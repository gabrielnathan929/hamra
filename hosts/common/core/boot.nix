# Boot configuration.
#
# Options:
#   loader - Bootloader. Supported: "systemd-boot" | "grub".
#            "grub" requires grub.device (e.g. "/dev/sda").
#   systemd.editor - Show the boot entry editor in the boot menu.
{hamraLib, ...}: {
  hamra.boot = hamraLib.mkBase {
    loader = "systemd-boot";
    grub.device = "/dev/sda";
    systemd.editor = false;
  };
}
