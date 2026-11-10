{
  config,
  lib,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "nvidia") {
  services.xserver.videoDrivers = ["nvidia"];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
  };
}
