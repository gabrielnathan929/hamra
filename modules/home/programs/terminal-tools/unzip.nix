{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.unzip;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.unzip = mkOption {
    type = types.bool;
    default = false;
    description = "Enable unzip.";
  };

  config.home.packages = mkIf cfg [pkgs.unzip];
}
