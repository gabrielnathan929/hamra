{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.remmina;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.remmina = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Remmina remote desktop.";
  };

  config.home.packages = mkIf cfg [pkgs.remmina];
}
