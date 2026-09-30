{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.grim;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.grim = mkOption {
    type = types.bool;
    default = true;
    description = "Enable grim screenshot.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.grim];
}
