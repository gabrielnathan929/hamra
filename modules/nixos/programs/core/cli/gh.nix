{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.gh;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.gh = mkOption {
    type = types.bool;
    default = true;
    description = "Enable GitHub CLI.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gh];
}
