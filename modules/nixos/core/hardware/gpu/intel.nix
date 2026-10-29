{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "intel") {
  services.thermald.enable = lib.mkDefault true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [pkgs.intel-media-driver];
    extraPackages32 = [pkgs.pkgsi686Linux.intel-media-driver];
  };

  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  environment.systemPackages = [pkgs.intel-gpu-tools];
}
