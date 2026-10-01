_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "plasma";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "plasma";
  };
}
