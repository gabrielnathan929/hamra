{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.apps.obsidian;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.apps.obsidian = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Obsidian Notes.";
  };

  config.home.packages = mkIf cfg [pkgs.obsidian];
}
