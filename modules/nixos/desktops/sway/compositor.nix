{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.desktop.default == "sway") {
  programs.sway = {
    enable = true;
    package = pkgs.swayfx;
    wrapperFeatures.gtk = true;
    xwayland.enable = true;
    extraSessionCommands = lib.mkIf (config.hamra.hardware.gpu == "virtio") (
      let
        backends =
          "drm,libinput"
          + lib.optionalString config.hamra.programs.optionals.services.wayvnc ",headless";
      in ''
        export WLR_BACKENDS=${backends}
        export WLR_NO_HARDWARE_DBUS=1
      ''
    );
  };

  services = {
    displayManager.defaultSession = lib.mkDefault "sway";
    gvfs.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [xdg-desktop-portal-wlr];
    configPackages = [pkgs.swayfx];
    config.sway.default = lib.mkForce ["wlr"];
  };
}
