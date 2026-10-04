{
  config,
  lib,
  pkgs,
  ...
}: let
  isVirtio = config.hamra.hardware.gpu == "virtio";
in {
  config = lib.mkIf isVirtio {
    boot.kernelModules = ["virtio-gpu"];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        libglvnd
      ];
    };

    users.users.${config.hamra.users.userName}.extraGroups = lib.mkBefore ["video"];

    services.spice-vdagentd.enable = lib.mkDefault true;

    services.qemuGuest.enable = lib.mkDefault true;
  };
}
