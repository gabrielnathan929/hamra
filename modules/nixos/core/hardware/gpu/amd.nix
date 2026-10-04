{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (config.hamra.hardware.gpu == "amd") {
  hardware.graphics = {
    enable32Bit = true;
    extraPackages = with pkgs; [
      amdvlk
    ];
  };
  hardware.amdgpu.amdvlk.enable = lib.mkDefault true;
}
