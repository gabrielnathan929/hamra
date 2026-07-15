{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.apps.spotify;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.apps.spotify = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Spotify.";
  };

  config.home.packages = mkIf (cfg && !config.hamra.home.programs.apps.spicetify) [
    pkgs.spotify
  ];
}
