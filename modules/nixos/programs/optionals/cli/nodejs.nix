{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.nodejs;
  inherit (lib) mkOption mkIf types;
  user = config.hamra.users.userName;
  userHome = config.users.users.${user}.home;
  npmGlobal = "${userHome}/.npm-global";
in {
  options.hamra.programs.optionals.cli.nodejs = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Node.js.";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.nodejs];

    environment.sessionVariables = {
      NPM_CONFIG_PREFIX = npmGlobal;
      PATH = ["${npmGlobal}/bin"];
    };
  };
}
