{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkAfter;
  cfg = config.programs.noctalia;

  linkedFiles = [
    "foot/foot.ini"
    "hypr/hyprland.lua"
    "fastfetch/config.jsonc"
  ];

  seededFiles = [
    "btop/btop.conf"
    "tmux/tmux.conf"
  ];

  iconThemes = [
    "Papirus-Dark"
    "Papirus-Light"
  ];

  prepare = pkgs.writeShellScript "noctalia-templates-prepare" ''
    set -eu

    config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
    data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"

    is_store_link() {
      local origin
      if [ ! -L "$1" ]; then
        return 1
      fi
      origin="$(readlink "$1" 2>/dev/null || true)"
      case "$origin" in
        ${builtins.storeDir}/*) return 0 ;;
        *) return 1 ;;
      esac
    }

    make_writable() {
      local dest="$1"
      local origin=""
      if is_store_link "$dest"; then
        origin="$(readlink -f "$dest")"
        cp --remove-destination "$origin" "$dest"
      fi
      if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        chmod u+w "$dest"
      fi
    }

    seed() {
      local dest="$config_home/$1"
      if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
        mkdir -p "$(dirname "$dest")"
        : >"$dest"
      fi
      make_writable "$dest"
    }

    for rel in ${lib.escapeShellArgs linkedFiles}; do
      make_writable "$config_home/$rel"
    done

    for rel in ${lib.escapeShellArgs seededFiles}; do
      seed "$rel"
    done

    mkdir -p "$data_home/icons"
    for theme in ${lib.escapeShellArgs iconThemes}; do
      if [ ! -e "$data_home/icons/$theme" ]; then
        cp -r "${pkgs.papirus-icon-theme}/share/icons/$theme" "$data_home/icons/$theme"
      fi
    done

    rm -f "$config_home"/foot/foot.ini.tmp.*
  '';
in {
  config = mkIf cfg.enable {
    home.activation.noctaliaTemplates = lib.hm.dag.entryAfter ["linkGeneration"] ''
      run ${prepare}

      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

      if ! run --quiet ${cfg.package}/bin/noctalia msg templates-apply; then
        warnEcho "noctalia templates could not be applied, run 'noctalia msg templates-apply' once the shell is running"
      fi
    '';

    programs.zsh.initContent = mkAfter ''
      if [ -r "''${XDG_CONFIG_HOME:-$HOME/.config}/fzf/themes/noctalia.sh" ]; then
        source "''${XDG_CONFIG_HOME:-$HOME/.config}/fzf/themes/noctalia.sh"
      fi
    '';
  };
}
