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
    networking.hostname = "test-vm";

    hardware = {
      gpu = "virtio";
      firmware = "uefi";
    };

    keyboard = {
      keymap = "us";
      xkbVariant = "intl";
    };

    desktop.default = "sway";

    programs.optionals = {
      gui = {
        firefox = false;
        wireshark = false;
      };
      media = {
        "davinci-resolve" = false;
      };
      packaging = {
        gearlever = false;
      };
      services = {
        appimage = false;
        samba = true;
      };
    };
  };
}
