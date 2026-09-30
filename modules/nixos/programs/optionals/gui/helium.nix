{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.helium;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.helium = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Helium browser.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.helium];
}
