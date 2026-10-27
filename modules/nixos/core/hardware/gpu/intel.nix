{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "intel") {
  services.thermald.enable = lib.mkDefault true;

  hardware.graphics = {
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  systemd.services.hamra-intel-dptf-powerlimit = {
    description = "Raise Intel DPTF MMIO RAPL power limit";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [pkgs.coreutils];
    script = ''
      f=/sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
      if [ -w "$f" ]; then
        echo 28000000 > "$f"
      fi
    '';
  };

  systemd.services.hamra-intel-dptf-powerlimit-refresh = {
    description = "Reassert Intel DPTF MMIO RAPL power limit";
    serviceConfig = {
      Type = "oneshot";
    };
    path = [pkgs.coreutils];
    script = ''
      f=/sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
      if [ -w "$f" ]; then
        echo 28000000 > "$f"
      fi
    '';
  };

  systemd.timers.hamra-intel-dptf-powerlimit-refresh = {
    description = "Periodic Intel DPTF RAPL refresh";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "15s";
      OnUnitActiveSec = "30s";
      Unit = "hamra-intel-dptf-powerlimit-refresh.service";
    };
  };
}
