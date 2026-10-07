_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "samsung";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    keyboard = {
      keymap = "us";
      xkbVariant = "intl";
    };

    desktop.default = "hyprland";

    programs.optionals.services.samba = true;
  };
}
