{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.zip;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.zip = mkOption {
    type = types.bool;
    default = false;
    description = "Enable zip.";
  };

  config.home.packages = mkIf cfg [pkgs.zip];
}
