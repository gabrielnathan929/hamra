{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.ncdu;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.ncdu = mkOption {
    type = types.bool;
    default = true;
    description = "Enable NCDU (disk usage analyzer for the terminal).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.ncdu];
}
