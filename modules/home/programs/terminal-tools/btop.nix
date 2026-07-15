{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.btop;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.btop = mkOption {
    type = types.bool;
    default = false;
    description = "Enable btop resource monitor.";
  };

  config.home.packages = mkIf cfg [pkgs.btop];
}
