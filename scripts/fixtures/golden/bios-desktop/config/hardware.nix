_: {
  hamra = {
    hardware = {
      bluetooth = true;
      brightness = true;
      firmware = "bios";
      gpu = "amd";
      touchpad = true;
    };

    keyboard = {
      keymap = "br";
      xkbVariant = "abnt2";
    };

    audio = {
      default = "pipewire";
    };

    boot = {
      grub = {
        device = "/dev/sda";
        useOSProber = false;
      };
      loader = "grub";
      systemd = {
        editor = false;
      };
    };
  };
}
