# Monitor layout for the desktops.
#
# Options:
#   physical.<name> - Per-monitor settings, e.g. mode "preferred" and
#                     position "0x0". Full schema in
#                     modules/nixos/core/hardware.
{hamraLib, ...}: {
  hamra.displays = hamraLib.mkBase {};
}
