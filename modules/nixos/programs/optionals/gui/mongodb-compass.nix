{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui."mongodb-compass";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui."mongodb-compass" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable MongoDB Compass (GUI for MongoDB).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.mongodb-compass];
}
