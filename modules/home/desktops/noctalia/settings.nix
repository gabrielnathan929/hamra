{
  config,
  wallpaperPath,
  ...
}: let
  homeDir = config.home.homeDirectory;
in {
  home.file = {
    "noctalia/captures/.keep".text = "";
    "noctalia/records/.keep".text = "";
    "noctalia/covers/anime/.keep".text = "";
    "noctalia/covers/manga/.keep".text = "";
    "noctalia/videos/.keep".text = "";
    "noctalia/notes/.keep".text = "";
  };

  programs.noctalia = {
    enable = true;
    systemd.enable = false;

    settings = {
      systemd.launch_apps_as_systemd_services = true;

      shell = {
        ui_scale = 1.0;
      };

      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/noctalia/wallpapers";
        default.path = "${wallpaperPath}";
        fill_mode = "crop";
      };

      shell.screenshot = {
        directory = "${config.home.homeDirectory}/noctalia/captures";
        saveToFile = true;
        copyToClipboard = true;
        freezeScreen = true;
      };

      plugin_settings = {
        "noctalia/screen_recorder" = {
          directory = "${config.home.homeDirectory}/noctalia/records";
          video_source = "focused";
          replay_enabled = true;
          replay_duration = 60;
        };
        "noctalia/mpvpaper" = {
          video_directory = "${config.home.homeDirectory}/noctalia/videos";
        };
        "noctalia/notes" = {
          notes_dir = "${config.home.homeDirectory}/noctalia/notes";
        };
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Noctalia";
      };
    };
  };
}
