{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.scripts."setup-gpg";
  inherit (lib) mkOption mkIf types;

  setup-gpg = pkgs.writeShellScriptBin "setup-gpg" ''
    set -euo pipefail

    gen_key() {
      gpg --full-generate-key
    }

    list_keys() {
      gpg --list-secret-keys --keyid-format LONG
    }

    import_file() {
      local f
      f=$(gum input --placeholder="Path to .asc/.gpg key file")
      [[ -z $f ]] && echo "Cancelled" && return 0
      [[ ! -f $f ]] && echo "Not found: $f" && return 1
      gpg --import "$f"
      echo "Imported: $f"
    }

    import_paste() {
      local tmp
      tmp=$(mktemp)
      ${pkgs.neovim}/bin/nvim "$tmp"
      if ! grep -q "BEGIN PGP PRIVATE KEY BLOCK" "$tmp"; then
        rm -f "$tmp" && echo "No key found." && return 1
      fi
      gpg --import "$tmp"
      rm -f "$tmp"
      echo "Imported from paste."
    }

    set_git_signing() {
      local key_id
      key_id=$(gpg --list-secret-keys --keyid-format LONG 2>/dev/null \
        | awk '/sec/{print $2}' | awk -F/ '{print $2}' | head -n1)
      if [[ -z $key_id ]]; then
        echo "No secret GPG key found. Generate one first."; return 0
      fi
      git config --global user.signingkey "$key_id"
      git config --global commit.gpgsign true
      echo "Git signing key set: $key_id"
    }

    edit_agent() {
      local dir="$HOME/.gnupg"
      mkdir -p "$dir" && chmod 700 "$dir"
      touch "$dir/gpg-agent.conf" && chmod 600 "$dir/gpg-agent.conf"
      ${pkgs.neovim}/bin/nvim "$dir/gpg-agent.conf"
    }

    main() {
      case "$(gum choose --cursor='▶ ' 'Generate key' 'Import from file' 'Import from paste' 'List keys' 'Set git signing key' 'Edit gpg-agent.conf' 'Cancel')" in
        "Generate key") gen_key ;;
        "Import from file") import_file ;;
        "Import from paste") import_paste ;;
        "List keys") list_keys ;;
        "Set git signing key") set_git_signing ;;
        "Edit gpg-agent.conf") edit_agent ;;
        *) echo "Cancelled" ;;
      esac
    }

    main
  '';
in {
  options.hamra.programs.core.scripts."setup-gpg" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable setup-gpg interactive TUI helper.";
  };

  config.environment.systemPackages = mkIf cfg [setup-gpg];
}
