# Machine hardware profile.
#
# Options:
#   gpu - Supported: "intel" | "amd" | "nvidia" | "virtio".
#   firmware - Supported: "uefi" | "bios".
#   bluetooth / brightness / touchpad - Base hardware toggles.
{hamraLib, ...}: {
  hamra.hardware = hamraLib.mkBase {
    gpu = "intel";
    firmware = "uefi";
    bluetooth = true;
    brightness = true;
    touchpad = true;
  };
}
