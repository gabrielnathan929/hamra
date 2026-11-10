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
      keymap = "br";
      xkbVariant = "abnt2";
    };

    audio = {
      default = "pipewire";
    };

    boot = {
      grub = {
        device = "";
        useOSProber = false;
      };
      loader = "systemd-boot";
      systemd = {
        editor = false;
      };
    };
  };
}
