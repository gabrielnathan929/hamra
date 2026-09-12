{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.tree;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.tree = mkOption {
    type = types.bool;
    default = true;
    description = "Enable tree.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.tree];
}
