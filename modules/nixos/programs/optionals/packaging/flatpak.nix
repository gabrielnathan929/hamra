{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.packaging.flatpak;
  apps = config.hamra.flatpak.apps;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
  userHome = config.users.users.${userName}.home;

  flatpakInstall = pkgs.writeShellScript "hamra-flatpak-install" ''
    set -euo pipefail
    flatpak=${pkgs.flatpak}/bin/flatpak
    "$flatpak" remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    for app in ${lib.escapeShellArgs apps}; do
      if "$flatpak" info --system "$app" >/dev/null 2>&1; then
        continue
      fi
      if HOME=${userHome} XDG_DATA_HOME=${userHome}/.local/share "$flatpak" info --user "$app" >/dev/null 2>&1; then
        continue
      fi
      "$flatpak" install --system --noninteractive -y flathub "$app"
    done
  '';
in {
  options.hamra.programs.optionals.packaging.flatpak = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Flatpak (universal package manager) support.";
  };

  options.hamra.flatpak.apps = mkOption {
    type = types.listOf types.str;
    default = [];
    example = ["com.discordapp.Discord" "org.videolan.VLC"];
    description = "Flatpak app IDs installed from Flathub on activation.";
  };

  config = mkIf cfg {
    services.flatpak.enable = true;
    services.packagekit.enable = true;
    environment.systemPackages = with pkgs; [
      gnome-software
    ];

    systemd.services.hamra-flatpak = mkIf (apps != []) {
      description = "Install declared Flatpak apps (hamra.flatpak.apps)";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = flatpakInstall;
      };
    };
  };
}
