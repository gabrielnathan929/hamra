{
  lib,
  hamraLib,
  ...
}: {
  options.hamra.hardware.gpu = lib.mkOption {
    type = lib.types.str;
    default = "intel";
    description = "GPU principal (intel, nvidia, amd, virtio).";
  };

  options.hamra.hardware.intel.xe = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "PCI device ID (from lspci -nn, e.g. 46a8) to bind to the xe driver instead of i915; null keeps i915.";
  };

  imports = hamraLib.scanPaths ./.;
}
