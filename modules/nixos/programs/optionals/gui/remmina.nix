{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.remmina;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.remmina = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Remmina remote desktop client.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.remmina];
}
