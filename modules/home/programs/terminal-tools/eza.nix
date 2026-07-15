{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.eza;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.eza = mkOption {
    type = types.bool;
    default = false;
    description = "Enable eza (ls replacement).";
  };

  config.home.packages = mkIf cfg [pkgs.eza];
}
