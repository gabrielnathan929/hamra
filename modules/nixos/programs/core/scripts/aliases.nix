{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts.aliases;
  inherit (lib) mkOption mkIf types;

  aliases = pkgs.writeShellApplication {
    name = "aliases";
    runtimeInputs = [pkgs.gnugrep pkgs.zsh];
    text = ''
      usage() {
        cat <<'EOF'
      usage: aliases [name]

        aliases          every shell alias, as name and command
        aliases <name>   only the aliases matching <name>
      EOF
      }

      collect() {
        zsh -ic 'for a in ''${(ok)aliases}; do printf "%s\t%s\n" "$a" "''${aliases[$a]}"; done' 2>/dev/null
      }

      show() {
        local name value
        while IFS=$'\t' read -r name value; do
          printf '%-24s %s\n' "$name" "$value"
        done < <(collect)
      }

      case "''${1:-}" in
        -h | --help) usage ;;
        "") show ;;
        *) show | grep -F -- "$1" ;;
      esac
    '';
  };
in {
  options.hamra.programs.core.scripts.aliases = mkOption {
    type = types.bool;
    default = true;
    description = "Enable aliases (list the shell aliases in a searchable menu).";
  };

  config = mkIf cfg {
    environment.systemPackages = [aliases];
  };
}
