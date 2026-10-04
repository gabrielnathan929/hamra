{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.hardware;
in
  lib.mkIf cfg.brightness {
    environment.systemPackages = with pkgs; [
      brightnessctl
    ];

    # Permite aos usuários do grupo video controlarem o brilho
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
    '';

    users.users.${config.hamra.users.userName}.extraGroups = ["video"];
  }
