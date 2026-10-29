_: {
  hamra = {
    hardware = {
      bluetooth = true;
      brightness = true;
      firmware = "uefi";
      gpu = "intel";
      cpu.intel.powerLimit = 15;
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
