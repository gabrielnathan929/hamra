{
  config,
  lib,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "nvidia") {
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
  };
}
