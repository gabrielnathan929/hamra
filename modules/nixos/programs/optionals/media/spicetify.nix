{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media.spicetify;
  inherit (lib) mkOption mkIf types;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in {
  options.hamra.programs.optionals.media.spicetify = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Spicetify with Marketplace for Spotify.";
  };

  config = mkIf cfg {
    environment.systemPackages = [config.programs.spicetify.spicetifyPackage];

    programs.spicetify = {
      enable = true;
      enabledCustomApps = [spicePkgs.apps.marketplace];
      enabledExtensions = [
        spicePkgs.extensions.popupLyrics
      ];
    };
  };
}
