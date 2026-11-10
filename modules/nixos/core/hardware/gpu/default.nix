{
  lib,
  hamraLib,
  ...
}: {
  options.hamra.hardware.gpu = lib.mkOption {
    type = lib.types.str;
    default = "intel";
    description = "Primary GPU (intel, nvidia, amd, virtio).";
  };

  imports = hamraLib.scanPaths ./.;
}
