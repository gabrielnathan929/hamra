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
    description = "Enable the boot menu editor in systemd-boot.";
  };

  options.hamra.hardware.firmware = lib.mkOption {
    type = lib.types.str;
    default = "uefi";
    description = "Firmware type (uefi or bios).";
  };

  config.boot = {
    loader = {
      systemd-boot = {
        enable = boot.loader == "systemd-boot";
        editor = boot.systemd.editor;
        configurationLimit = gc.maxGenerations;
      };
      timeout = lib.mkIf (boot.loader == "systemd-boot") (lib.mkDefault 5);
      efi.canTouchEfiVariables = hardware.firmware == "uefi";
    };
  };
}
