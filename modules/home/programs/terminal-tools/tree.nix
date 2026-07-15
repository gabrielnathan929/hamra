{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.tree;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.tree = mkOption {
    type = types.bool;
    default = false;
    description = "Enable tree.";
  };

  config.home.packages = mkIf cfg [pkgs.tree];
}
