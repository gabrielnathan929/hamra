# Desktop environment selection.
#
# Options:
#   default - Supported: "hyprland" | "niri" | "sway" | "gnome" | "plasma".
{hamraLib, ...}: {
  hamra.desktop.default = hamraLib.mkBase "hyprland";
}
