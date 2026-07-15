{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.wget;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.wget = mkOption {
    type = types.bool;
    default = false;
    description = "Enable wget.";
  };

  config.home.packages = mkIf cfg [pkgs.wget];
}
