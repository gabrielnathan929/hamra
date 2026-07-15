{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.tmux;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.tmux = mkOption {
    type = types.bool;
    default = false;
    description = "Enable tmux terminal multiplexer.";
  };

  config.home.packages = mkIf cfg [pkgs.tmux];
}
