{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.fastfetch;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.fastfetch = mkOption {
    type = types.bool;
    default = false;
    description = "Enable fastfetch.";
  };

  config.home.packages = mkIf cfg [pkgs.fastfetch];
}
