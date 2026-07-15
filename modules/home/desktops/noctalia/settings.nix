{
  config,
  wallpaperPath,
  ...
}: {
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

      plugins.screen_recorder = {
        directory = "${config.home.homeDirectory}/Videos/Recordings";
        video_source = "portal";
        replay_enabled = true;
        replay_duration = 60;
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Noctalia";
      };
    };
  };
}
