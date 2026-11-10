_: {
  hamra = {
    hardware = {
      bluetooth = true;
      brightness = true;
      firmware = "uefi";
      gpu = "virtio";
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
