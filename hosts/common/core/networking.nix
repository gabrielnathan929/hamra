# Network identity.
#
# Options:
#   hostname - Must match the host name registered in flake/hosts.nix.
{hamraLib, ...}: {
  hamra.networking.hostname = hamraLib.mkBase "nixos";
}
