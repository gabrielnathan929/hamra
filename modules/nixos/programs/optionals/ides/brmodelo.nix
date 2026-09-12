{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides.brmodelo;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides.brmodelo = mkOption {
    type = types.bool;
    default = false;
    description = "Enable BRModelo (database modeling tool - MER).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.brmodelo];
}
