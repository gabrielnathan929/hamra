{
  config,
  lib,
  hamraLib,
  ...
}: {
  options.hamra.hardware.gpu = lib.mkOption {
    type = lib.types.str;
    default = "virtio";
    description = "GPU principal (intel, nvidia, amd, virtio).";
  };

  imports = hamraLib.scanPaths ./.;
}
