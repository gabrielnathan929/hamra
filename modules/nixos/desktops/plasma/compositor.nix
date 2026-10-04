{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.desktop.default == "plasma") {
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.defaultSession = lib.mkDefault "plasma";
    gvfs.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      kdePackages.xdg-desktop-portal-kde
      xdg-desktop-portal-gtk
    ];
    config.common.default = ["kde"];
  };
}
