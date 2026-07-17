{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.development.docker;
  inherit (lib) mkOption mkIf mkDefault types;
in {
  options.hamra.programs.optionals.development.docker = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Docker Engine.";
  };

  config = mkIf cfg {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = mkDefault false;
      autoPrune.enable = mkDefault true;
    };
    users.users.${config.hamra.users.userName}.extraGroups = ["docker"];
    environment.systemPackages = with pkgs; [docker];
  };
}
