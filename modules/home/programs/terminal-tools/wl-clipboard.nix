{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.wl-clipboard;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.wl-clipboard = mkOption {
    type = types.bool;
    default = false;
    description = "Enable wl-clipboard.";
  };

  config.home.packages = mkIf cfg [pkgs.wl-clipboard];
}
