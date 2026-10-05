{lib, ...}: {
  imports = [
    ./gpu
    ./peripherals
    ./power.nix
  ];

  hardware.graphics.enable = lib.mkDefault true;
}
