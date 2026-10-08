# Audio server configuration.
#
# Options:
#   default - Audio backend. Supported: "pipewire".
{hamraLib, ...}: {
  hamra.audio.default = hamraLib.mkBase "pipewire";
}
