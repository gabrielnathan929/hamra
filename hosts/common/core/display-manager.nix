# Login screen (display manager) configuration.
#
# Options:
#   default - Supported: "sddm" | "greetd" (noctalia-greeter).
#   sddm.theme - SDDM theme. Supported: "silent".
#   sddm.preset - SilentSDDM preset, e.g. "catppuccin-mocha".
#
# The sddm.* options only apply when default is "sddm".
{hamraLib, ...}: {
  hamra.displayManager = hamraLib.mkBase {
    default = "sddm";
    sddm = {
      theme = "silent";
      preset = "catppuccin-mocha";
    };
  };
}
