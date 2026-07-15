{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.gum;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.gum = mkOption {
    type = types.bool;
    default = false;
    description = "Enable gum TUI toolkit.";
  };

  config.home.packages = mkIf cfg [pkgs.gum];
}
