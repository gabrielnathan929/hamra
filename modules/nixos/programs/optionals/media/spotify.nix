{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media.spotify;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.media.spotify = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Spotify.";
  };

  config.environment.systemPackages = mkIf (cfg && !config.hamra.programs.optionals.media.spicetify) [
    pkgs.spotify
  ];
}
