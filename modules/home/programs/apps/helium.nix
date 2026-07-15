{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.apps.helium;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.apps.helium = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Helium browser.";
  };

  config.home.packages = mkIf cfg [pkgs.helium];
}
