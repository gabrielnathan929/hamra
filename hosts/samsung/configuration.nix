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

    programs.optionals.services.wayvnc = true;
  };
}
