{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.eza;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.eza = mkOption {
    type = types.bool;
    default = true;
    description = "Enable eza (ls replacement).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.eza];
}
