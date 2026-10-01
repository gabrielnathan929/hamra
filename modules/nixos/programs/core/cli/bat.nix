{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.bat;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.bat = mkOption {
    type = types.bool;
    default = true;
    description = "Enable bat.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.bat];
}
