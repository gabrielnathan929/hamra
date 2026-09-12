{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.hardware;
in
  lib.mkIf cfg.bluetooth {
    hardware.bluetooth = {
      enable = lib.mkDefault true;
      powerOnBoot = lib.mkDefault true;

      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      bluez-tools
    ];

    users.users.${config.hamra.users.userName}.extraGroups = lib.mkBefore ["bluetooth"];
  }
