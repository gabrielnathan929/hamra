_: {
  hamra = {
    hardware = {
      bluetooth = false;
      brightness = false;
      firmware = "uefi";
      gpu = "virtio";
      touchpad = false;
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
