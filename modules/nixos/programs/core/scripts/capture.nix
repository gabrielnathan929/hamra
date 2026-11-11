{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts.capture;
  inherit (lib) mkOption mkIf types;

  capture = pkgs.writeShellApplication {
    name = "capture";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.ffmpeg
      pkgs.gpu-screen-recorder
      pkgs.jq
      pkgs.procps
      pkgs.util-linux
    ];
    text = ''
      usage() {
        printf '%s\n' \
          'usage: capture [command]' \
          ''' \
          '  capture                    menu: record the screen or take a screenshot' \
          '  capture record [mode]      record the screen (menu, or a mode directly)' \
          '  capture screenshot [mode]  take a screenshot (menu, or a mode directly)' \
          '  capture stop               stop the current recording' \
          '  capture -h                 show this help' \
          ''' \
          'Record modes: none, desktop, both, webcam' \
          'Screenshot modes: region, window, monitor, annotate'
      }

      gsr_re='^(/nix/store/.*-)?gpu-screen-recorder'

      has_noctalia() {
        command -v noctalia >/dev/null 2>&1
      }

      notify() {
        has_noctalia || return 0
        noctalia msg notification-show "$1" "$2" >/dev/null 2>&1 || true
      }

      menu() {
        local prompt="$1"
        shift
        if ! has_noctalia; then
          printf '%s\n' 'capture: noctalia not found on PATH' >&2
          return 1
        fi
        printf '%s\n' "$@" | noctalia dmenu -p "$prompt"
      }

      recording_active() {
        pgrep -f "$gsr_re" >/dev/null 2>&1
      }

      focused_output() {
        local name=""
        if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1; then
          name="$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null)"
        elif [[ -n "''${NIRI_SOCKET:-}" ]] && command -v niri >/dev/null 2>&1; then
          name="$(niri msg --json focused-output 2>/dev/null | jq -r '.name' 2>/dev/null)"
        elif [[ -n "''${SWAYSOCK:-}" ]] && command -v swaymsg >/dev/null 2>&1; then
          name="$(swaymsg -t get_outputs 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null)"
        fi
        if [[ -z $name ]]; then
          name="$(gpu-screen-recorder --list-monitors 2>/dev/null | head -n1 | cut -d'|' -f1)"
        fi
        printf '%s\n' "$name"
      }

      webcam_device() {
        local dev
        for dev in /dev/video*; do
          [[ -e $dev ]] || continue
          printf '%s\n' "$dev"
          return 0
        done
        return 1
      }

      webcam_pid_file() {
        printf '%s\n' "''${XDG_RUNTIME_DIR:-/tmp}/hamra-capture-webcam.pid"
      }

      start_webcam() {
        local dev="''${CAPTURE_WEBCAM_DEVICE:-}"
        if [[ -z $dev ]]; then
          dev="$(webcam_device)" || return 1
        fi
        setsid ffplay -f v4l2 -framerate 30 "$dev" \
          -vf "scale=480:-2" \
          -window_title WebcamOverlay -noborder \
          -fflags nobuffer -flags low_delay -probesize 32 -analyzeduration 0 \
          -loglevel quiet >/dev/null 2>&1 &
        printf '%s\n' "$!" > "$(webcam_pid_file)"
      }

      stop_webcam() {
        local file
        local pid
        file="$(webcam_pid_file)"
        if [[ -f $file ]]; then
          pid="$(cat "$file")"
          if [[ -n $pid ]]; then
            kill "$pid" >/dev/null 2>&1 || true
          fi
          rm -f "$file"
        fi
        pkill -f 'ffplay.*WebcamOverlay' >/dev/null 2>&1 || true
      }

      start_recording() {
        local mode="$1"
        local audio=""
        local webcam=0
        local label
        case "$mode" in
          none)
            audio=""
            label="sem áudio"
            ;;
          desktop)
            audio="default_output"
            label="áudio do sistema"
            ;;
          both)
            audio="default_output|default_input"
            label="sistema + microfone"
            ;;
          webcam)
            audio="default_output|default_input"
            webcam=1
            label="sistema + microfone + webcam"
            ;;
          *)
            printf 'capture: unknown record mode: %s\n' "$mode" >&2
            exit 2
            ;;
        esac

        if recording_active; then
          notify "Captura" "Já existe uma gravação em andamento."
          return 0
        fi

        local dir="''${CAPTURE_DIR:-$HOME/noctalia/records}"
        mkdir -p "$dir"
        local out
        out="$dir/recording_$(date +%Y%m%d-%H%M%S).mp4"

        local source
        source="$(focused_output)"
        if [[ -z $source ]]; then
          notify "Captura" "Nenhum monitor encontrado para gravar."
          return 1
        fi

        local -a args=(-w "$source" -fm vfr -f 60 -k h264 -bm qp -ffmpeg-video-opts qp=25 -cursor yes -cr limited -v no -o "$out")
        if [[ -n $audio ]]; then
          args+=(-ac opus -a "$audio")
        fi

        if [[ $webcam -eq 1 ]]; then
          if ! start_webcam; then
            notify "Captura" "Nenhuma webcam encontrada em /dev/video*."
            return 1
          fi
        fi

        setsid gpu-screen-recorder "''${args[@]}" >/dev/null 2>&1 &
        sleep 1
        if ! recording_active; then
          stop_webcam
          notify "Captura" "Falha ao iniciar a gravação."
          return 1
        fi
        notify "Captura" "Gravando ($label) em $out"
      }

      stop_recording() {
        stop_webcam
        pkill -SIGINT -f "$gsr_re" >/dev/null 2>&1 || true
        notify "Captura" "Gravação finalizada."
      }

      screenshot() {
        case "$1" in
          region) noctalia msg screenshot-region ;;
          window) noctalia msg screenshot-window ;;
          monitor) noctalia msg screenshot-fullscreen ;;
          annotate) noctalia msg screenshot-annotate ;;
          *)
            printf 'capture: unknown screenshot mode: %s\n' "$1" >&2
            exit 2
            ;;
        esac
      }

      record_menu() {
        local choice
        if recording_active; then
          choice="$(menu "Gravação em andamento" "Parar gravação" "Sem áudio" "Áudio do sistema" "Sistema + microfone" "Sistema + microfone + webcam")" || return 0
          if [[ $choice == "Parar gravação" ]]; then
            stop_recording
            return 0
          fi
        else
          choice="$(menu "Gravar tela" "Sem áudio" "Áudio do sistema" "Sistema + microfone" "Sistema + microfone + webcam")" || return 0
        fi
        case "$choice" in
          "Sem áudio") start_recording none ;;
          "Áudio do sistema") start_recording desktop ;;
          "Sistema + microfone") start_recording both ;;
          "Sistema + microfone + webcam") start_recording webcam ;;
          *) return 0 ;;
        esac
      }

      screenshot_menu() {
        local choice
        choice="$(menu "Captura de tela" "Região" "Janela" "Monitor" "Anotar região")" || return 0
        case "$choice" in
          "Região") screenshot region ;;
          "Janela") screenshot window ;;
          "Monitor") screenshot monitor ;;
          "Anotar região") screenshot annotate ;;
          *) return 0 ;;
        esac
      }

      main_menu() {
        local choice
        choice="$(menu "Captura" "Gravar tela" "Captura de tela")" || return 0
        case "$choice" in
          "Gravar tela") record_menu ;;
          "Captura de tela") screenshot_menu ;;
          *) return 0 ;;
        esac
      }

      case "''${1:-}" in
        -h | --help) usage ;;
        record)
          shift
          if [[ -n "''${1:-}" ]]; then
            start_recording "$1"
          else
            record_menu
          fi
          ;;
        screenshot)
          shift
          if [[ -n "''${1:-}" ]]; then
            screenshot "$1"
          else
            screenshot_menu
          fi
          ;;
        stop) stop_recording ;;
        "") main_menu ;;
        *)
          printf 'capture: unknown command: %s\n' "$1" >&2
          usage >&2
          exit 2
          ;;
      esac
    '';
  };
in {
  options.hamra.programs.core.scripts.capture = mkOption {
    type = types.bool;
    default = true;
    description = "Enable the capture menu: screen recording with selectable audio (system, microphone, webcam overlay) and screenshots, driven by the Noctalia dmenu launcher.";
  };

  config = mkIf cfg {
    environment.systemPackages = [capture];
  };
}
