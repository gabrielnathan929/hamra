{
  config,
  lib,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "amd") {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
