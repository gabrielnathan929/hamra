{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.drawio;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.drawio = mkOption {
    type = types.bool;
    default = false;
    description = "Enable draw.io (diagramming application).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.drawio];
}
