{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.desktop.default == "niri") {
  programs.niri = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [xwayland-satellite];

  services = {
    displayManager.defaultSession = lib.mkDefault "niri";
    gvfs.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [xdg-desktop-portal-gtk];
    config.common.default = ["gtk"];
  };
}
