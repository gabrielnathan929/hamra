{
  lib,
  config,
  ...
}: let
  cfg = config.hamra.hardware.power;
in {
  options.hamra.hardware.power = {
    epp = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable intel_pstate active so power-profiles-daemon drives the energy performance preference (balance_power on battery, performance on AC).";
    };

    aspm = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Force PCIe Active State Power Management. Some NVMe and Wi-Fi devices misbehave with it.";
    };

    psr = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable i915 Panel Self Refresh. Saves battery but causes flicker on some panels.";
    };
  };

  config.boot.kernelParams =
    lib.optionals cfg.epp ["intel_pstate=active"]
    ++ lib.optionals cfg.aspm ["pcie_aspm=force"]
    ++ lib.optionals cfg.psr ["i915.enable_psr=1"];
}
