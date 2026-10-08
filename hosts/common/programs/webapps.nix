# Web apps (site opened in its own window).
#
# Options:
#   <name>.url - Required. Page opened by the wrapper.
#   <name>.desktopName - Required. Name shown in the app menu.
#   <name>.icon - Optional. 512x512 PNG URL; requires iconHash.
{hamraLib, ...}: {
  hamra.webapps = hamraLib.mkBase {};
}
