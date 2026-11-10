{
  lib,
  hamraLib,
  ...
}: {
  options.hamra.hardware = {
    bluetooth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Bluetooth.";
    };
    brightness = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable brightness control (brightnessctl).";
    };
    touchpad = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable touchpad (libinput).";
    };
  };

  imports = hamraLib.scanPaths ./.;
}
