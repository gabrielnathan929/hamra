# Base security services.
#
# Options:
#   polkit / keyring / gnupg / sshd - Disabling these can break the
#   session, the secrets or remote access.
{hamraLib, ...}: {
  hamra.services = hamraLib.mkBase {
    polkit = true;
    keyring = true;
    gnupg = true;
    sshd = true;
  };
}
