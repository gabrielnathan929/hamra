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

  imports = hamraLib.scanPaths ./.;
}
