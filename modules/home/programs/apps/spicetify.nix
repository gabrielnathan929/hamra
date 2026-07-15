{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.hamra.home.programs.apps.spicetify;
  inherit (lib) mkOption mkIf types;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  options.hamra.home.programs.apps.spicetify = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Spicetify with Marketplace for Spotify.";
  };

  config = mkIf cfg {
    programs.spicetify = {
      enable = true;
      spotifyPackage = pkgs.spotify;
      enabledCustomApps = [spicePkgs.apps.marketplace spicePkgs.apps.lyricsPlus];
    };
  };
}
