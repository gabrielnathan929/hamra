{
  config,
  lib,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "nvidia") {
  hardware.graphics.enable32Bit = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
  };
}
