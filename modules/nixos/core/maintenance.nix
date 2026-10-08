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
      description = "Enable automatic garbage collection.";
    };
    maxGenerations = lib.mkOption {
      type = lib.types.int;
      default = 20;
      description = "Maximum number of generations kept.";
    };
    schedule = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = "Cleanup frequency (daily, weekly).";
    };
    keepDays = lib.mkOption {
      type = lib.types.int;
      default = 30;
      description = "Days to retain generations.";
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
