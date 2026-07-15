{
  config,
  lib,
  ...
}:
lib.mkIf (config.hamra.desktop.default == "hyprland") {
  hamra.displays = {
    physical = lib.mkIf (config.hamra.hardware.gpu == "intel") {
      "eDP-1" = {
        mode = lib.mkDefault "1920x1080";
        position = lib.mkDefault "0x0";
        scale = lib.mkDefault 1.0;
      };
    };
    virtual = lib.mkIf (config.hamra.hardware.gpu == "virtio") {
      "Virtual-1" = {
        mode = lib.mkDefault "1920x1080";
        position = lib.mkDefault "0x0";
        scale = lib.mkDefault 1.0;
      };
    };
    headless = lib.mkIf config.hamra.programs.services.wayvnc {
      "HEADLESS-1" = {
        mode = lib.mkDefault "1920x1080@60";
        position = lib.mkDefault "1920x0";
        scale = lib.mkDefault 1.0;
      };
    };
  };
}
