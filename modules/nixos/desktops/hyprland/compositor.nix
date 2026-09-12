{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.desktop.default == "hyprland") {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services = {
    displayManager.defaultSession = lib.mkDefault "hyprland";
    gvfs.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
    configPackages = [pkgs.hyprland];
    config.hyprland.default = ["hyprland"];
    config.common.default = ["hyprland"];
  };
}
