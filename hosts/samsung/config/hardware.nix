_: {
  hamra = {
    hardware = {
      bluetooth = true;
      brightness = true;
      firmware = "uefi";
      gpu = "intel";
      touchpad = true;
    };

    keyboard = {
      keymap = "us";
      xkbVariant = "intl";
    };

    audio = {
      default = "pipewire";
    };

    boot = {
      grub = {
        device = "/dev/sda";
        useOSProber = false;
      };
      loader = "systemd-boot";
      systemd = {
        editor = false;
      };
    };
  };
}
