{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.pkgs.apps;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.pkgs.apps = mkOption {
    type = types.bool;
    default = true;
    description = "Enable common application packages (Obsidian).";
  };

  config.home.packages = mkIf cfg (with pkgs; [
    obsidian
  ]);
}
