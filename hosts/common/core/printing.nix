# Printing support.
#
# Options:
#   printing - Enable CUPS.
{hamraLib, ...}: {
  hamra.printing = hamraLib.mkBase true;
}
