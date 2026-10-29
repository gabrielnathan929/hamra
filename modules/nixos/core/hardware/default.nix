{lib, ...}: {
  imports = [
    ./cpu
    ./gpu
    ./peripherals
  ];

  hardware.graphics.enable = lib.mkDefault true;
}
