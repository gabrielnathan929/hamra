{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.tmux;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.tmux = mkOption {
    type = types.bool;
    default = true;
    description = "Enable tmux terminal multiplexer.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.tmux];
}
