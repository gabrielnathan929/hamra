{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.noctalia.evtest;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.noctalia.evtest = mkOption {
    type = types.bool;
    default = true;
    description = "Enable evtest (input device event monitor, Noctalia plugin dependency).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.evtest];
}
