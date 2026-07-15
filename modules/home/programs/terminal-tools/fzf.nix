{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.fzf;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.fzf = mkOption {
    type = types.bool;
    default = false;
    description = "Enable fzf fuzzy finder.";
  };

  config.home.packages = mkIf cfg [pkgs.fzf];
}
