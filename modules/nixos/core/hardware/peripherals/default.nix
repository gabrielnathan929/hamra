{
  config,
  lib,
  hamraLib,
  ...
}: {
  options.hamra.hardware = {
    bluetooth = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Habilitar bluetooth.";
    };
    brightness = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Habilitar controle de brilho (brightnessctl).";
    };
    touchpad = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Habilitar touchpad (libinput).";
    };
  };

  imports = hamraLib.scanPaths ./.;
}
