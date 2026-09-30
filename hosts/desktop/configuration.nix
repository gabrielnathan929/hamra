_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "desktop";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "hyprland";
  };
}
