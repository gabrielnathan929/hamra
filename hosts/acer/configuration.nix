_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "acer";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "hyprland";

    programs.optionals.services.samba = true;
  };
}
