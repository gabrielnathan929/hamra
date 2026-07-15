{lib, ...}: {
  imports = [
    ./gpu
    ./peripherals
  ];

  hardware.graphics.enable = lib.mkDefault true;
}
