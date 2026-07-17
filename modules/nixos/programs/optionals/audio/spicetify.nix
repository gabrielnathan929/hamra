{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.hamra.programs.optionals.audio.spicetify;
  inherit (lib) mkOption mkIf types;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
in {
  options.hamra.programs.optionals.audio.spicetify = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Spicetify with Marketplace for Spotify.";
  };

  config = mkIf cfg {
    programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";
      enabledCustomApps = [spicePkgs.apps.marketplace];
      enabledExtensions = [
        spicePkgs.extensions.popupLyrics
      ];
    };
  };
}
