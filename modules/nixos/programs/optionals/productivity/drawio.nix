{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.productivity.drawio;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.productivity.drawio = mkOption {
    type = types.bool;
    default = false;
    description = "Enable draw.io (diagramming application).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.drawio];
}
