_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "gnome";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "gnome";
  };
}
