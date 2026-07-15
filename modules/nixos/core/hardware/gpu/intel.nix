{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "intel") {
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];
}
