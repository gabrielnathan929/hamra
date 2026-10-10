{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts.keybinds;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;

  manifest = builtins.toJSON config.home-manager.users.${userName}.hamra.keybinds;

  keys = pkgs.writeShellApplication {
    name = "keys";
    runtimeInputs = [pkgs.jq];
    text = ''
      manifest=/etc/hamra/keybinds.json

      usage() {
        printf '%s\n' 'Usage: keys [context]'
        printf '\n'
        printf '%s\n' \
          '  keys            shortcuts of the active window manager' \
          '  keys <context>  shortcuts of one context (hyprland, sway, niri, tmux, herdr, all)' \
          '  keys -h         show this help'
      }

      detect_context() {
        if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
          echo hyprland
        elif [[ -n "''${SWAYSOCK:-}" ]]; then
          echo sway
        elif [[ -n "''${NIRI_SOCKET:-}" ]]; then
          echo niri
        elif [[ -n "''${XDG_CURRENT_DESKTOP:-}" ]]; then
          echo "''${XDG_CURRENT_DESKTOP,,}"
        else
          echo ""
        fi
      }

      print_context() {
        local ctx=$1
        local rows
        rows=$(jq -r --arg ctx "$ctx" '(.[$ctx] // [])[] | "\(.key)\t\(.action)"' "$manifest")
        printf '\n%s\n' "''${ctx^}"
        if [[ -z $rows ]]; then
          printf '  (no shortcuts declared for this context)\n'
          return 0
        fi
        while IFS=$'\t' read -r key action; do
          printf '  %-30s %s\n' "$key" "$action"
        done <<< "$rows"
      }

      if [[ ! -f $manifest ]]; then
        echo "keys: manifest not found: $manifest" >&2
        exit 1
      fi

      context=''${1:-}

      case $context in
        -h | --help)
          usage
          exit 0
          ;;
        "")
          context=$(detect_context)
          if [[ -z $context ]]; then
            usage
            exit 1
          fi
          printf 'Shortcuts — %s\n' "$context"
          print_context "$context"
          ;;
        all)
          printf 'Shortcuts by context\n'
          while read -r ctx; do
            print_context "$ctx"
          done < <(jq -r 'keys[]' "$manifest")
          ;;
        *)
          printf 'Shortcuts — %s\n' "$context"
          print_context "$context"
          ;;
      esac
    '';
  };
in {
  options.hamra.programs.core.scripts.keybinds = mkOption {
    type = types.bool;
    default = true;
    description = "Enable keys (shortcuts by context: active WM, tmux, herdr).";
  };

  config = mkIf cfg {
    environment.systemPackages = [keys];

    environment.etc."hamra/keybinds.json".text = manifest;
  };
}
