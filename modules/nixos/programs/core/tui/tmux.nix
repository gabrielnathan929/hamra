{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.tui.tmux;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.tui.tmux = mkOption {
    type = types.bool;
    default = true;
    description = "Enable tmux terminal multiplexer.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.tmux];
}
