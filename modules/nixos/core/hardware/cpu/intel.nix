{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.hardware.cpu.intel;
  inherit (lib) mkOption mkIf types;

  powerLimitScript = pkgs.writeShellScript "intel-powerlimit" ''
    limit=${toString (cfg.powerLimit * 1000000)}
    for target in /sys/class/powercap/intel-rapl-mmio:*/constraint_0_power_limit_uw \
                  /sys/class/powercap/intel-rapl:*/constraint_0_power_limit_uw; do
      if [ -w "$target" ]; then
        printf '%s\n' "$limit" > "$target"
      fi
    done
  '';
in {
  options.hamra.hardware.cpu.intel.powerLimit = mkOption {
    type = types.nullOr types.ints.positive;
    default = null;
    example = 15;
    description = "Long-term package power limit (PL1) in watts. null keeps the firmware value. The i5-1235U declares 15 W as its maximum; firmware that ships 13 W leaves the iGPU below the power it needs on its own and the GPU throttles its clock.";
  };

  config = mkIf (cfg.powerLimit != null) {
    systemd.services.hamra-intel-powerlimit = {
      description = "Apply the Intel SoC long-term power limit (hamra.hardware.cpu.intel.powerLimit)";
      wantedBy = ["multi-user.target"];
      after = ["systemd-modules-load.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = powerLimitScript;
      };
    };

    powerManagement.resumeCommands = "${powerLimitScript}";
  };
}
