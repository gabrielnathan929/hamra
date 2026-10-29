{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "intel") {
  services.thermald.enable = lib.mkDefault true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
    ];
  };

  boot.kernelParams = lib.optionals (config.hamra.hardware.intel.xe != null) [
    "i915.force_probe=!${config.hamra.hardware.intel.xe}"
    "xe.force_probe=${config.hamra.hardware.intel.xe}"
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  systemd = {
    services.hamra-intel-dptf-powerlimit = {
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

    services.hamra-intel-dptf-powerlimit-refresh = {
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

    timers.hamra-intel-dptf-powerlimit-refresh = {
      description = "Periodic Intel DPTF RAPL refresh";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "15s";
        OnUnitActiveSec = "30s";
        Unit = "hamra-intel-dptf-powerlimit-refresh.service";
      };
    };
  };
}
