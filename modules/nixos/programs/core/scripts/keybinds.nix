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

  hamra-keybinds = pkgs.writeShellApplication {
    name = "hamra-keybinds";
    runtimeInputs = [pkgs.jq];
    text = ''
      manifest=/etc/hamra/keybinds.json

      usage() {
        printf '%s\n' 'Uso: hamra-keybinds [contexto]'
        printf '\n'
        printf '%s\n' \
          '  hamra-keybinds            atalhos do window manager ativo' \
          '  hamra-keybinds <contexto> atalhos de um contexto (hyprland, sway, niri, tmux, herdr, all)' \
          '  hamra-keybinds -h         mostra esta ajuda'
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
          printf '  (nenhum atalho declarado para este contexto)\n'
          return 0
        fi
        while IFS=$'\t' read -r key action; do
          printf '  %-30s %s\n' "$key" "$action"
        done <<< "$rows"
      }

      if [[ ! -f $manifest ]]; then
        echo "hamra-keybinds: manifesto não encontrado: $manifest" >&2
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
          printf 'Atalhos — %s\n' "$context"
          print_context "$context"
          ;;
        all)
          printf 'Atalhos por contexto\n'
          while read -r ctx; do
            print_context "$ctx"
          done < <(jq -r 'keys[]' "$manifest")
          ;;
        *)
          printf 'Atalhos — %s\n' "$context"
          print_context "$context"
          ;;
      esac
    '';
  };
in {
  options.hamra.programs.core.scripts.keybinds = mkOption {
    type = types.bool;
    default = true;
    description = "Enable hamra-keybinds (atalhos por contexto: WM ativo, tmux, herdr).";
  };

  config = mkIf cfg {
    environment.systemPackages = [hamra-keybinds];

    environment.etc."hamra/keybinds.json".text = manifest;
  };
}
