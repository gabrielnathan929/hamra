{
  config,
  lib,
  ...
}: let
  gc = config.hamra.gc;
  boot = config.hamra.boot;
  hardware = config.hamra.hardware;
in {
  options.hamra.boot.systemd.editor = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Habilitar editor no systemd-boot.";
  };

  options.hamra.hardware.firmware = lib.mkOption {
    type = lib.types.str;
    default = "uefi";
    description = "Tipo de firmware (uefi ou bios).";
  };

  config.boot = {
    loader = {
      systemd-boot = {
        enable = boot.loader == "systemd-boot";
        editor = boot.systemd.editor;
        configurationLimit = gc.maxGenerations;
      };
      timeout = lib.mkDefault 10;
      efi.canTouchEfiVariables = hardware.firmware == "uefi";
    };
  };
}
