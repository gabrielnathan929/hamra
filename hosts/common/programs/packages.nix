# Extra system packages.
#
# Options:
#   extra - Packages outside the toggle modules.
{hamraLib, ...}: {
  hamra.packages.extra = hamraLib.mkBase [];
}
