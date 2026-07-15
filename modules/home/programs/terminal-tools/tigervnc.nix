{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.tigervnc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.tigervnc = mkOption {
    type = types.bool;
    default = false;
    description = "Enable TigerVNC.";
  };

  config.home.packages = mkIf cfg [pkgs.tigervnc];
}
