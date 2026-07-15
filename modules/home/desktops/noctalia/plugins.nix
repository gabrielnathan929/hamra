_: {
  programs.noctalia.settings.plugins = {
    enabled = [
      "noctalia/notes"
      "noctalia/timer"
      "noctalia/bongocat"
      "noctalia/mpvpaper"
      "noctalia/wallhaven"
      "noctalia/translator"
      "noctalia/screen_recorder"
      "oldirtty/color_picker"
      "gabrielnathan929/myanimelist"
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
