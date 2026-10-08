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
    networking.hostname = "vm";

    hardware = {
      gpu = "virtio";
      firmware = "uefi";
    };

    desktop.default = "sway";

    programs.optionals = {
      media."davinci-resolve" = false;
      services.wayvnc = false;
    };
  };
}
