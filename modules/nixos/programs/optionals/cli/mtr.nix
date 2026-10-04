{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.mtr;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.mtr = mkOption {
    type = types.bool;
    default = false;
    description = "Enable mtr.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.mtr];
}
