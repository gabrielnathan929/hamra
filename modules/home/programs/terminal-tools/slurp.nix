{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.slurp;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.slurp = mkOption {
    type = types.bool;
    default = false;
    description = "Enable slurp region selector.";
  };

  config.home.packages = mkIf cfg [pkgs.slurp];
}
