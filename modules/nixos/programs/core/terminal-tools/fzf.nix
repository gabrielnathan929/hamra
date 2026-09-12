{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.fzf;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.fzf = mkOption {
    type = types.bool;
    default = true;
    description = "Enable fzf fuzzy finder.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.fzf];
}
