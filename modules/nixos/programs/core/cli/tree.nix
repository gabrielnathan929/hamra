{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.tree;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.tree = mkOption {
    type = types.bool;
    default = true;
    description = "Enable tree.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.tree];
}
