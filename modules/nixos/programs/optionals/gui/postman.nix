{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.postman;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.postman = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Postman (API platform for building and testing APIs).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.postman];
}
