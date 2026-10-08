{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.services.gtk;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.core.services.gtk = mkOption {
    type = types.bool;
    default = true;
    description = "Configure GTK/Qt icon theme and settings for folder icons.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [
      bibata-cursors
      glib
      gsettings-desktop-schemas
      papirus-icon-theme
    ];

    systemd.tmpfiles.rules = [
      "L+ /usr/share/icons/Papirus - - - - ${pkgs.papirus-icon-theme}/share/icons/Papirus"
      "L+ /usr/share/icons/Papirus-Dark - - - - ${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark"
      "L+ /usr/share/icons/Papirus-Light - - - - ${pkgs.papirus-icon-theme}/share/icons/Papirus-Light"
    ];

    home-manager.users.${userName} = {
      gtk = {
        enable = true;

        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      qt = {
        enable = true;

        platformTheme.name = "qtct";

        style.name = "kvantum";

        qt5ctSettings.Appearance.icon_theme = "Papirus-Dark";
        qt6ctSettings.Appearance.icon_theme = "Papirus-Dark";
      };
    };
  };
}
