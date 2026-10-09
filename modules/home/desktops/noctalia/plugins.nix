_: {
  programs.noctalia.settings.plugins = {
    enabled = [
      "noctalia/bitwarden"
      "noctalia/bongocat"
      "noctalia/mpvpaper"
      "noctalia/notes"
      "noctalia/timer"
      "noctalia/translator"
      "noctalia/kaomoji"
      "noctalia/wallhaven"
      "noctalia/wallpaper_depth"
      "noctalia/world_clock"
      "noctalia/screen_recorder"
      "oldirtty/color_picker"
      "gabrielnathan929/myanimelist"
      "gabrielnathan929/controlfreak"
    ];

    source = [
      {
        name = "official";
        kind = "git";
        location = "https://github.com/gabrielnathan929/official-plugins";
        auto_update = true;
      }
      {
        name = "community";
        kind = "git";
        location = "https://github.com/gabrielnathan929/community-plugins";
        auto_update = true;
      }
    ];
  };
}
