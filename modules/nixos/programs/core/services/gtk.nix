{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.services.gtk;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.services.gtk = mkOption {
    type = types.bool;
    default = true;
    description = "Configure GTK icon theme and settings for folder icons.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      bibata-cursors
      glib
      gsettings-desktop-schemas
    ];

    systemd.tmpfiles.rules = [
      "L+ /usr/share/icons/Papirus - - - - ${pkgs.papirus-icon-theme}/share/icons/Papirus"
      "L+ /usr/share/icons/Papirus-Dark - - - - ${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark"
      "L+ /usr/share/icons/Papirus-Light - - - - ${pkgs.papirus-icon-theme}/share/icons/Papirus-Light"
    ];

    environment.sessionVariables = {
      GTK_ICON_THEME = "Papirus";
      GTK_CURSOR_THEME = "Bibata-Modern-Classic";
    };
  };
}
