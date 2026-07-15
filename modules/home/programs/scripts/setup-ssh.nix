{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.scripts.setup-ssh;
  inherit (lib) mkOption mkIf types;

  setup-ssh = pkgs.writeShellScriptBin "setup-ssh" ''
    set -euo pipefail

    SSH_DIR="$HOME/.ssh"
    KEY_PATH="$SSH_DIR/id_ed25519"
    CONFIG="$SSH_DIR/config"
    PUB_PATH="$KEY_PATH.pub"

    ensure_dir() {
      mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"
    }

    backup() {
      local f=$1
      [[ -f $f ]] && cp "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"
    }

    gen_key() {
      local email
      email=$(gum input --placeholder="email for SSH key comment")
      [[ -z $email ]] && echo "Cancelled" && return 0
      [[ -f $KEY_PATH ]] && echo "Key already exists at $KEY_PATH" && return 0
      ssh-keygen -t ed25519 -C "$email" -f "$KEY_PATH"
      chmod 600 "$KEY_PATH" && chmod 644 "$PUB_PATH"
      echo "Generated: $KEY_PATH"
      ssh-add "$KEY_PATH" 2>/dev/null || true
    }

    import_file() {
      local src
      src=$(gum input --placeholder="Path to private key file")
      [[ -z $src ]] && echo "Cancelled" && return 0
      [[ ! -f $src ]] && echo "Not found: $src" && return 1
      ensure_dir && backup "$KEY_PATH"
      cp "$src" "$KEY_PATH" && chmod 600 "$KEY_PATH"
      ssh-keygen -y -f "$KEY_PATH" > "$PUB_PATH" && chmod 644 "$PUB_PATH"
      echo "Imported: $KEY_PATH"
      ssh-add "$KEY_PATH" 2>/dev/null || true
    }

    import_paste() {
      local tmp
      tmp=$(mktemp)
      ${pkgs.neovim}/bin/nvim "$tmp"
      if ! grep -q "BEGIN OPENSSH PRIVATE KEY" "$tmp"; then
        rm -f "$tmp" && echo "No key found." && return 1
      fi
      ensure_dir && backup "$KEY_PATH"
      cp "$tmp" "$KEY_PATH" && chmod 600 "$KEY_PATH"
      ssh-keygen -y -f "$KEY_PATH" > "$PUB_PATH" && chmod 644 "$PUB_PATH"
      rm -f "$tmp"
      echo "Imported from paste: $KEY_PATH"
      ssh-add "$KEY_PATH" 2>/dev/null || true
    }

    show_pub() {
      if [[ ! -f $PUB_PATH ]]; then
        echo "No public key at $PUB_PATH"; return 0
      fi
      cat "$PUB_PATH"
    }

    edit_config() {
      ensure_dir && touch "$CONFIG" && chmod 600 "$CONFIG"
      ${pkgs.neovim}/bin/nvim "$CONFIG"
    }

    main() {
      ensure_dir
      case "$(gum choose --cursor='▶ ' 'Generate key' 'Import from file' 'Import from paste' 'Show public key' 'Edit config' 'Add key to ssh-agent' 'Cancel')" in
        "Generate key") gen_key ;;
        "Import from file") import_file ;;
        "Import from paste") import_paste ;;
        "Show public key") show_pub ;;
        "Edit config") edit_config ;;
        "Add key to ssh-agent") ssh-add "$KEY_PATH" 2>/dev/null || echo "No key at $KEY_PATH" ;;
        *) echo "Cancelled" ;;
      esac
    }

    main
  '';
in {
  options.hamra.home.programs.scripts.setup-ssh = mkOption {
    type = types.bool;
    default = false;
    description = "Enable setup-ssh interactive TUI helper.";
  };

  config.home.packages = mkIf cfg [setup-ssh];
}
