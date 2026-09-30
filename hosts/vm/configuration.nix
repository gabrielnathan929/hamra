_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "vm";

    hardware = {
      gpu = "virtio";
      firmware = "uefi";
    };

    desktop.default = "sway";

    programs.optionals.services.wayvnc = true;
    programs.optionals.gui.notion = true;
  };
}
