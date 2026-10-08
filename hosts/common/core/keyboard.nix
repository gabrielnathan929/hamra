# Keyboard configuration.
#
# Options:
#   keymap - XKB layout, e.g. "us" or "br".
#   xkbVariant - XKB variant, e.g. "intl", "abnt2" or "dvorak".
{hamraLib, ...}: {
  hamra.keyboard = hamraLib.mkBase {
    keymap = "br";
    xkbVariant = "abnt2";
  };
}
