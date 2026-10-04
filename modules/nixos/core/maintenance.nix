{
  config,
  lib,
  ...
}: let
  gc = config.hamra.gc;
in {
  options.hamra.gc = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Habilitar garbage collection automático.";
    };
    maxGenerations = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = "Máximo de gerações mantidas.";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "Frequência da limpeza (daily, weekly).";
    };
    keepDays = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Dias de retenção de gerações.";
    };
  };

  config = lib.mkIf gc.enable {
    nix.gc = {
      automatic = true;
      dates = gc.schedule;
      options = "--delete-older-than ${toString gc.keepDays}d";
    };
    nix.optimise = {
      automatic = true;
      dates = [gc.schedule];
    };
  };
}
