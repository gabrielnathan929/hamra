{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.grim;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.grim = mkOption {
    type = types.bool;
    default = false;
    description = "Enable grim screenshot.";
  };

  config.home.packages = mkIf cfg [pkgs.grim];
}
