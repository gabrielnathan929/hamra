{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.desktop.default == "gnome") {
  services = {
    desktopManager.gnome.enable = true;
    displayManager.defaultSession = lib.mkDefault "gnome";
    gvfs.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config.common.default = ["gnome"];
  };
}
