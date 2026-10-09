{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;

  cfg = config.hamra.programs.optionals.services.wayvnc;
  supported = builtins.elem config.hamra.desktop.default ["hyprland" "sway"];
  userName = config.hamra.users.userName;

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  swaymsg = "${pkgs.swayfx}/bin/swaymsg";
  openssl = "${pkgs.openssl}/bin/openssl";

  headlessDisplays = config.hamra.displays.headless or {};
  headlessNames = builtins.attrNames headlessDisplays;

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
        info "  SWAYSOCK        = (nao encontrado)"
      fi
    }

    wait_compositor() {
      info "Aguardando compositor (timeout: $TIMEOUT sec)..."
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
      error "Nenhum compositor apos $TIMEOUT sec"
      return 1
    }

    # Nomes headless declarados na config (ex: HEADLESS-1).
    WANTED_NAMES="${lib.concatStringsSep " " headlessNames}"

    # Hyprland 0.55 ignores explicit names when creating headless outputs and
    # generates HEADLESS-N automatically. We detect the real name at runtime.
    detect_hyprland_headless() {
      ${hyprctl} monitors all 2>/dev/null \
        | grep -oE 'HEADLESS-[0-9]+' \
        | sort -u \
        | tail -1 || true
    }

    monitor_rule_for() {
      # Aplica mode/position/scale da config ao output real detectado.
      local name=$1
      local rule
      rule=$(${pkgs.jq}/bin/jq -n \
        --arg name "$name" \
        --argjson displays '${builtins.toJSON headlessDisplays}' \
        -r '.displays[$name] // (.displays[keys[0]] // {}) | "\(.mode // "1920x1080@60") \(.position // "1920x0") \(.scale // 1)"' 2>/dev/null)
      read -r h_mode h_position h_scale <<<"$rule"
      info "Hyprland: aplicando regra para $name (''${h_mode} em ''${h_position}, scale ''${h_scale})"
      ${hyprctl} eval "hl.monitor({ output = \"$name\", mode = \"''${h_mode}\", position = \"''${h_position}\", scale = ''${h_scale} })" >/dev/null 2>&1 || true
    }

    move_workspaces() {
      # Workspaces 6-10 para o monitor headless real.
      # API Lua 0.55: cria o workspace (focus) antes de mover, pois
      # moveworkspacetomonitor falha se o workspace nao existe.
      for ws in 6 7 8 9 10; do
        ${hyprctl} eval "hl.dispatch(hl.dsp.focus({ workspace = $ws }))" >/dev/null 2>&1 || true
        ${hyprctl} eval "hl.dispatch(hl.dsp.workspace.move({ workspace = $ws, monitor = '$1' }))" >/dev/null 2>&1 || true
      done
      info "Hyprland: workspaces 6-10 movidos para $1"
    }

    setup_headless() {
      local compositor=$1

      case "$compositor" in
        hyprland)
          # Se ja existe um headless (ex: sessao anterior), reutiliza.
          local real
          real=$(detect_hyprland_headless)
          if [ -n "$real" ]; then
            info "Hyprland: output headless existente: $real"
            monitor_rule_for "$real"
            move_workspaces "$real"
            echo "$real"
            return 0
          fi

          info "Hyprland: criando output headless (sem nome explicito)..."
          ${hyprctl} output create headless >/dev/null 2>&1 || true
          for _ in $(seq 1 15); do
            real=$(detect_hyprland_headless)
            if [ -n "$real" ]; then
              break
            fi
            sleep "$SLEEP"
          done

          if [ -z "$real" ]; then
            error "Hyprland: falha ao criar output headless"
            return 1
          fi

          info "Hyprland: output criado: $real"
          monitor_rule_for "$real"
          move_workspaces "$real"
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
            info "Sway: criando output headless ..."
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
            error "Sway: falha ao criar $WANTED_NAMES"
            return 1
          fi

          info "Sway: output headless: $real"
          echo "$real"
          ;;
      esac
    }

    ensure_tls() {
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/wayvnc"
      mkdir -p "$state_dir"
      chmod 700 "$state_dir"
      if [ ! -f "$state_dir/tls.crt" ] || [ ! -f "$state_dir/tls.key" ] || [ ! -f "$state_dir/rsa.pem" ]; then
        info "Gerando certificado TLS autoassinado em $state_dir ..."
        ${openssl} req -x509 -newkey rsa:2048 -keyout "$state_dir/tls.key" -out "$state_dir/tls.crt" -days 825 -nodes -subj "/CN=hamra-vnc" 2>/dev/null
        ${openssl} genrsa -out "$state_dir/rsa.pem" 2048 2>/dev/null
        chmod 600 "$state_dir/tls.key" "$state_dir/rsa.pem"
      fi
      echo "$state_dir"
    }

    write_auth_config() {
      secret_file=$1
      state_dir=$2
      if [ ! -f "$secret_file" ]; then
        error "Segredo vnc-password ausente em $secret_file (sops)."
        error "Gere com: nix develop --command sops secrets/vnc.yaml"
        return 1
      fi
      pw=$(tr -d '\n\r' <"$secret_file")
      if [ -z "$pw" ]; then
        error "Segredo vnc-password vazio."
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
      compositor=$(wait_compositor) || exit 1
      output=$(setup_headless "$compositor") || exit 1
      tls_dir=$(ensure_tls)
      auth_conf=$(write_auth_config "${config.sops.secrets."vnc-password".path}" "$tls_dir") || exit 1

      info "Iniciando wayvnc no output '$output' (porta $VNC_ADDR:5900, auth TLS)..."
      exec ${lib.getExe pkgs.wayvnc} \
        --config="$auth_conf" \
        "$VNC_ADDR" \
        --max-fps="$VNC_FPS" \
        --output="$output"
    }

    main
  '';
in {
  options.hamra.programs.optionals.services.wayvnc = mkOption {
    type = types.bool;
    default = false;
    description = "Habilitar WayVNC (porta 5900, auth com senha via sops + TLS). Requer Hyprland ou Sway.";
  };

  config = mkIf (cfg && supported) {
    programs.wayvnc.enable = true;
    networking.firewall.allowedTCPPorts = [5900];

    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    sops.secrets."vnc-password" = {
      sopsFile = ../../../../../secrets/vnc.yaml;
      owner = userName;
      mode = "0400";
    };

    systemd.user.services.wayvnc = {
      description = "WayVNC — Remote Desktop (Hyprland/Sway)";
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 10;
        ExecStart = "${wayvncDaemon}";
      };
    };
  };
}
