{
  config,
  lib,
  ...
}: let
  audio = config.hamra.audio;
in {
  options.hamra.audio.default = lib.mkOption {
    type = lib.types.str;
    default = "pipewire";
    description = "Default audio system (pipewire).";
  };

  config = {
    security.rtkit.enable = true;
    services.pipewire = lib.mkIf (audio.default == "pipewire") {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
