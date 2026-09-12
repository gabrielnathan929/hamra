{
  config,
  lib,
  ...
}: let
  gc = config.hamra.gc;
  boot = config.hamra.boot;
in {
  options.hamra.boot = {
    grub = {
      device = lib.mkOption {
        type = lib.types.str;
        default = "/dev/sda";
        description = "Dispositivo para instalação do GRUB.";
      };
      useOSProber = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Habilitar OS Prober no GRUB.";
      };
    };
  };

  config.boot = {
    loader = {
      grub = {
        enable = boot.loader == "grub";
        device = lib.mkIf (boot.loader == "grub") boot.grub.device;
        useOSProber = boot.grub.useOSProber;
        configurationLimit = gc.maxGenerations;
      };
      timeout = lib.mkDefault 10;
    };
  };
}
