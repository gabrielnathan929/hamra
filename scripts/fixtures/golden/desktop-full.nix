_: {
  imports = [
    ../../modules/nixos/core
    ../../modules/nixos/desktops
    ../../modules/nixos/programs
    ../common
    ../profiles/gabrielnathan
    ./hardware-configuration.nix
  ];

  hamra = {
    networking.hostname = "test-desktop";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "hyprland";
  };
}
