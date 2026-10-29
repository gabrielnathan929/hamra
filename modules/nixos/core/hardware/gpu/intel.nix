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

  systemd.services.hamra-intel-powerlimit = {
    description = "Hold the Intel DPTF MMIO RAPL limit at 28 W";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 5;
    };
    path = [pkgs.coreutils];
    script = ''
      f=/sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
      while true; do
        if [ -w "$f" ]; then
          echo 28000000 > "$f"
        fi
        sleep 5
      done
    '';
  };
}
