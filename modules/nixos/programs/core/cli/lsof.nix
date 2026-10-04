{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.lsof;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.lsof = mkOption {
    type = types.bool;
    default = true;
    description = "Enable lsof.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.lsof];
}
