{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.browsers.helium;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.browsers.helium = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Helium browser.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.helium];
}
