{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.vesktop;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.vesktop = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Vesktop.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.vesktop];
}
