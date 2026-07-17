{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.hamra.programs.audio.spicetify;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.audio.spicetify = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Spicetify with Marketplace for Spotify.";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.spotify
    pkgs.spicetify-cli
  ];
}
