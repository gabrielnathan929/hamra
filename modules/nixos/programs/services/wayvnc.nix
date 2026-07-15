{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf types;

  cfg = config.hamra.programs.services.wayvnc;
  supported = builtins.elem config.hamra.desktop.default ["hyprland" "sway"];

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
  swaymsg = "${pkgs.swayfx}/bin/swaymsg";

  name = "HEADLESS-1";

  wayvncDaemon = pkgs.writeShellScript "wayvnc-daemon" ''
    set -e

    NAME="${name}"
    VNC_PORT="0.0.0.0"
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

    setup_headless() {
      local compositor=$1

      case "$compositor" in
        hyprland)
          if ! ${hyprctl} monitors all 2>/dev/null | grep -q "Monitor $NAME "; then
            info "Hyprland: criando $NAME ..."
            ${hyprctl} output create headless "$NAME" >/dev/null 2>&1 || true
            for _ in $(seq 1 15); do
              if ${hyprctl} monitors all 2>/dev/null | grep -q "Monitor $NAME "; then
                break
              fi
              sleep "$SLEEP"
            done
            ${hyprctl} keyword monitor "$NAME,1920x1080@60,1920x0,1" >/dev/null 2>&1 || true
            ${hyprctl} dispatch moveworkspacetomonitor 6 "$NAME" >/dev/null 2>&1 || true
          else
            info "Hyprland: $NAME ja existe"
          fi
          ;;

        sway)
          if ! ${swaymsg} -t get_outputs 2>/dev/null | grep -q "$NAME"; then
            info "Sway: criando $NAME ..."
            ${swaymsg} create_output >/dev/null 2>&1 || true
            for _ in $(seq 1 15); do
              if ${swaymsg} -t get_outputs 2>/dev/null | grep -q "$NAME"; then
                break
              fi
              sleep "$SLEEP"
            done
          fi

          if ! ${swaymsg} -t get_outputs 2>/dev/null | grep -q "$NAME"; then
            error "Sway: falha ao criar $NAME"
            return 1
          fi

          if ${swaymsg} output "$NAME" resolution 1920x1080 >/dev/null 2>&1; then
            info "Sway: $NAME configurado (1920x1080)"
          else
            warn "Sway: nao foi possivel aplicar resolucao"
          fi
          ;;
      esac
    }

    main() {
      setup_env
      compositor=$(wait_compositor) || exit 1
      setup_headless "$compositor" || exit 1

      info "Iniciando wayvnc no output '$NAME' (porta $VNC_PORT:5900)..."
      exec ${lib.getExe pkgs.wayvnc} \
        "$VNC_PORT" \
        --max-fps="$VNC_FPS" \
        --output="$NAME"
    }

    main
  '';
in {
  options.hamra.programs.services.wayvnc = mkOption {
    type = types.bool;
    default = false;
    description = "Habilitar WayVNC (porta 5900). Requer Hyprland ou Sway.";
  };

  config = mkIf (cfg && supported) {
    programs.wayvnc.enable = true;
    networking.firewall.allowedTCPPorts = [5900];

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
