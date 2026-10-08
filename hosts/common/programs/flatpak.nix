# Flatpak apps.
#
# Options:
#   apps - Flathub IDs installed by the hamra-flatpak service.
#          Requires programs.optionals.packaging.flatpak.
{hamraLib, ...}: {
  hamra.flatpak.apps = hamraLib.mkBase [];
}
