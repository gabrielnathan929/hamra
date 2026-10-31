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
  userName = config.hamra.users.userName;
  userHome = config.users.users.${userName}.home;
  spotifyPath = "${config.programs.spicetify.spicetifyPackage}/share/spotify";
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
      enabledCustomApps = [spicePkgs.apps.marketplace spicePkgs.apps.lyricsPlus];
      enabledExtensions = [
        spicePkgs.extensions.popupLyrics
      ];
    };

    home-manager.users.${userName}.xdg.configFile."spicetify/config-xpui.ini" = {
      force = true;
      text = ''
        [Setting]
        replace_colors         = 1
        always_enable_devtools = 0
        overwrite_assets       = 0
        spotify_launch_flags   =
        check_spicetify_update = 1
        spotify_path           = ${spotifyPath}
        prefs_path             = ${userHome}/.config/spotify/prefs
        current_theme          =
        color_scheme           =
        inject_theme_js        = 1
        inject_css             = 1

        [Preprocesses]
        disable_sentry     = 1
        disable_ui_logging = 1
        remove_rtl_rule    = 1
        expose_apis        = 1

        [AdditionalOptions]
        custom_apps           =
        sidebar_config        = 0
        home_config           = 1
        experimental_features = 1
        extensions            =

        [Patch]

        [Backup]
        version =
        with    =
      '';
    };
  };
}
