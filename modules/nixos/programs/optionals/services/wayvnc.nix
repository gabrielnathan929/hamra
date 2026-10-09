{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;

  cfg = config.hamra.programs.optionals.services.wayvnc;
  noAuth = config.hamra.programs.optionals.services."wayvnc-no-auth";
  authSecret = lib.optionalString (!noAuth) config.sops.secrets."vnc-password".path;
  supported = builtins.elem config.hamra.desktop.default ["hyprland" "sway"];
  userName = config.hamra.users.userName;

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  swaymsg = "${pkgs.swayfx}/bin/swaymsg";
  openssl = "${pkgs.openssl}/bin/openssl";
  ssh-keygen = "${pkgs.openssh}/bin/ssh-keygen";
  flock = "${pkgs.util-linux}/bin/flock";

  headlessDisplays = config.hamra.displays.headless or {};
  headlessNames = builtins.attrNames headlessDisplays;
  headlessFallback =
    if headlessNames == []
    then {}
    else headlessDisplays.${lib.head headlessNames};

  wayvncDaemon = pkgs.writeShellScript "wayvnc-daemon" ''
      set -e

      VNC_ADDR="0.0.0.0"
      VNC_FPS=30
      TIMEOUT=90
      SLEEP=1

      log() { echo "[wayvnc] [$(date '+%T')] [$1] $2" >&2; }
      info()  { log "INFO"  "$1"; }
      warn()  { log "WARN"  "$1"; }
      error() { log "ERROR" "$1" >&2; }
      debug() { [ -n "$WAYVNC_DEBUG" ] && log "DEBUG" "$1"; }

      setup_env() {
        XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export XDG_RUNTIME_DIR

        if [ -z "$WAYLAND_DISPLAY" ]; then
          WAYLAND_DISPLAY=$(ls "$XDG_RUNTIME_DIR"/wayland-* 2>/dev/null \
            | grep -v '\.lock$' | head -1 | xargs basename 2>/dev/null \
            || echo "wayland-1")
        fi
        export WAYLAND_DISPLAY

        if [ -z "$SWAYSOCK" ]; then
          SWAYSOCK=$(ls "$XDG_RUNTIME_DIR"/sway-ipc.*.sock 2>/dev/null | head -1 || true)
        fi
        export SWAYSOCK

        info "Environment:"
        info "  XDG_RUNTIME_DIR = $XDG_RUNTIME_DIR"
        info "  WAYLAND_DISPLAY = $WAYLAND_DISPLAY"
        if [ -n "$SWAYSOCK" ]; then
          info "  SWAYSOCK        = $SWAYSOCK"
        else
          info "  SWAYSOCK        = (not found)"
        fi
      }

      wait_compositor() {
        info "Waiting for compositor (timeout: $TIMEOUT sec)..."
        for _ in $(seq 1 "$TIMEOUT"); do
          if ${hyprctl} monitors >/dev/null 2>&1; then
            info "Compositor: hyprland"
            echo "hyprland"
            return 0
          fi
          if [ -n "$SWAYSOCK" ] && ${swaymsg} -t get_outputs >/dev/null 2>&1; then
            info "Compositor: sway"
            echo "sway"
            return 0
          fi
          sleep "$SLEEP"
        done
        error "No compositor after $TIMEOUT sec"
        return 1
      }

      WANTED_NAMES="${lib.concatStringsSep " " headlessNames}"

      detect_hyprland_headless_all() {
        ${hyprctl} monitors all 2>/dev/null \
          | grep -oE 'HEADLESS-[0-9]+' \
          | sort -u -t- -k2 -n || true
      }

      detect_hyprland_headless() {
        detect_hyprland_headless_all | tail -1 || true
      }

      prune_hyprland_headless() {
        local keep=$1 name stale
        stale=$(detect_hyprland_headless_all | grep -vFx "$keep" || true)
        for name in $stale; do
          info "Hyprland: removing stale headless output: $name"
          ${hyprctl} output remove "$name" >/dev/null 2>&1 || warn "Hyprland: failed to remove $name"
        done
      }

    hyprland_spec_for() {
      local name=$1
      ${pkgs.jq}/bin/jq -n -r \
        --arg name "$name" \
        --argjson displays '${builtins.toJSON headlessDisplays}' \
        --argjson fallback '${builtins.toJSON headlessFallback}' \
        '$displays[$name] // $fallback | "\(.mode // "1920x1080@60") \(.position // "1920x0") \(.scale // 1.0)"'
    }

    apply_hyprland_rules() {
      local target=$1 mode=$2 position=$3 scale=$4 ws cur out
      cur=$(${hyprctl} activeworkspace -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.id // empty')
      info "Hyprland: monitor rule: $target,$mode,$position,$scale"
      if ! out=$(${hyprctl} eval "hl.monitor({ output = '$target', mode = '$mode', position = '$position', scale = $scale })" 2>&1); then
        warn "Hyprland: failed to apply monitor rule for $target: $out"
      fi
      for ws in 6 7 8 9 10; do
        ${hyprctl} dispatch moveworkspacetomonitor "$ws,$target" >/dev/null 2>&1 \
          || warn "Hyprland: failed to move workspace $ws to $target"
        ${hyprctl} eval "hl.workspace_rule({ workspace = \"$ws\", monitor = '$target', persistent = true })" >/dev/null 2>&1 \
          || warn "Hyprland: failed to bind workspace $ws to $target"
      done
      if [ -n "$cur" ]; then
        ${hyprctl} dispatch workspace "$cur" >/dev/null 2>&1 || true
      fi
    }

    hyprland_settled() {
      local target=$1 scale=$2 ok
      ok=$(${hyprctl} monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r --arg mon "$target" --argjson want "$scale" '[.[] | select(.name == $mon)] | length == 1 and .[0].scale == $want')
      [ "$ok" = "true" ] || return 1
      ok=$(${hyprctl} workspaces -j 2>/dev/null | ${pkgs.jq}/bin/jq -r --arg mon "$target" '[.[] | select(.monitor == $mon) | .id] as $ids | [6,7,8,9,10] - $ids | length == 0')
      [ "$ok" = "true" ]
    }

    settle_hyprland() {
      local target=$1 mode position scale i
      read -r mode position scale <<<"$(hyprland_spec_for "$target")"
      for i in $(seq 1 6); do
        apply_hyprland_rules "$target" "$mode" "$position" "$scale"
        if hyprland_settled "$target" "$scale"; then
          info "Hyprland: output $target settled (scale $scale, workspaces 6-10 present)"
          return 0
        fi
        info "Hyprland: output $target not settled yet, re-applying..."
        sleep 2
      done
      warn "Hyprland: output $target did not settle, continuing anyway"
    }

      setup_headless() {
        local compositor=$1

        case "$compositor" in
          hyprland)
            local real
            real=$(detect_hyprland_headless)
            if [ -n "$real" ]; then
              info "Hyprland: existing headless output: $real"
              prune_hyprland_headless "$real"
              settle_hyprland "$real"
              echo "$real"
              return 0
            fi

            info "Hyprland: creating headless output (no explicit name)..."
            ${hyprctl} output create headless >/dev/null 2>&1 || true
            for _ in $(seq 1 15); do
              real=$(detect_hyprland_headless)
              if [ -n "$real" ]; then
                break
              fi
              sleep "$SLEEP"
            done

            if [ -z "$real" ]; then
              error "Hyprland: failed to create headless output"
              return 1
            fi

            info "Hyprland: output created: $real"
            prune_hyprland_headless "$real"
            settle_hyprland "$real"
            echo "$real"
            ;;

          sway)
            local real=""
            for name in $WANTED_NAMES; do
              if ${swaymsg} -t get_outputs 2>/dev/null | grep -q "$name"; then
                real=$name
                break
              fi
            done

            if [ -z "$real" ]; then
              info "Sway: creating headless output ..."
              ${swaymsg} create_output >/dev/null 2>&1 || true
              for _ in $(seq 1 15); do
                for name in $WANTED_NAMES; do
                  if ${swaymsg} -t get_outputs 2>/dev/null | grep -q "$name"; then
                    real=$name
                    break
                  fi
                done
                [ -n "$real" ] && break
                sleep "$SLEEP"
              done
            fi

            if [ -z "$real" ]; then
              error "Sway: failed to create $WANTED_NAMES"
              return 1
            fi

            info "Sway: headless output: $real"
            echo "$real"
            ;;
        esac
      }

      ensure_tls() {
        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/wayvnc"
        mkdir -p "$state_dir"
        chmod 700 "$state_dir"
        if [ ! -f "$state_dir/tls.crt" ] || [ ! -f "$state_dir/tls.key" ]; then
          info "Generating self-signed TLS certificate in $state_dir ..."
          ${openssl} req -x509 -newkey rsa:2048 -keyout "$state_dir/tls.key" -out "$state_dir/tls.crt" -days 825 -nodes -subj "/CN=hamra-vnc" 2>/dev/null
          chmod 600 "$state_dir/tls.key"
        fi
        if ! grep -q "BEGIN RSA PRIVATE KEY" "$state_dir/rsa.pem" 2>/dev/null; then
          info "Generating RSA key for wayvnc in $state_dir ..."
          rm -f "$state_dir/rsa.pem"
          ${ssh-keygen} -m pem -t rsa -b 2048 -N "" -f "$state_dir/rsa.pem" -q
          chmod 600 "$state_dir/rsa.pem"
        fi
        echo "$state_dir"
      }

      write_auth_config() {
        secret_file=$1
        state_dir=$2
        if [ ! -f "$secret_file" ]; then
          error "vnc-password secret missing at $secret_file (sops)."
          error "Create it with: nix develop --command sops secrets/vnc.yaml"
          return 1
        fi
        pw=$(tr -d '\n\r' <"$secret_file")
        if [ -z "$pw" ]; then
          error "vnc-password secret is empty."
          return 1
        fi
        conf="$XDG_RUNTIME_DIR/wayvnc.conf"
        {
          echo "enable_auth=true"
          echo "username=${userName}"
          echo "password=$pw"
          echo "private_key_file=$state_dir/tls.key"
          echo "certificate_file=$state_dir/tls.crt"
          echo "rsa_private_key_file=$state_dir/rsa.pem"
        } >"$conf"
        chmod 600 "$conf"
        echo "$conf"
      }

      main() {
        setup_env
        exec 9>"$XDG_RUNTIME_DIR/wayvnc-setup.lock"
        if ! ${flock} -n 9; then
          info "Another setup in progress, retrying later..."
          exit 1
        fi
        compositor=$(wait_compositor) || exit 1
        output=$(setup_headless "$compositor") || exit 1
        if [ "$1" = "--open" ]; then
          info "Starting wayvnc on output '$output' (port $VNC_ADDR:5900, no auth)..."
          ${flock} -u 9
          exec ${lib.getExe pkgs.wayvnc} \
            "$VNC_ADDR" \
            --max-fps="$VNC_FPS" \
            --output="$output"
        fi
        tls_dir=$(ensure_tls)
        auth_conf=$(write_auth_config "${authSecret}" "$tls_dir") || exit 1

        info "Starting wayvnc on output '$output' (port $VNC_ADDR:5900, TLS auth)..."
        ${flock} -u 9
        exec ${lib.getExe pkgs.wayvnc} \
          --config="$auth_conf" \
          "$VNC_ADDR" \
          --max-fps="$VNC_FPS" \
          --output="$output"
      }

      main "$@"
  '';
in {
  options.hamra.programs.optionals.services.wayvnc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable WayVNC (port 5900, sops password + TLS auth). Requires Hyprland or Sway.";
  };

  options.hamra.programs.optionals.services."wayvnc-no-auth" = mkOption {
    type = types.bool;
    default = false;
    description = "Expose WayVNC without password or TLS. Anyone on the network can control the desktop.";
  };

  config = mkIf (cfg && supported) (lib.mkMerge [
    {
      programs.wayvnc.enable = true;
      networking.firewall.allowedTCPPorts = [5900];

      systemd.user.services.wayvnc = {
        description = "WayVNC — Remote Desktop (Hyprland/Sway)";
        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 10;
          ExecStart = "${wayvncDaemon}${lib.optionalString noAuth " --open"}";
        };
      };
    }
    (lib.mkIf (!noAuth) {
      sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      sops.secrets."vnc-password" = {
        sopsFile = ../../../../../secrets/vnc.yaml;
        owner = userName;
        mode = "0400";
      };
    })
  ]);
}
