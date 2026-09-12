{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides."mongodb-compass";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides."mongodb-compass" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable MongoDB Compass (GUI for MongoDB).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.mongodb-compass];
}
