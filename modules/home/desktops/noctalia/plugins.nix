_: {
  programs.noctalia.settings.plugins = {
    enabled = [
      "noctalia/bongocat"
      "noctalia/mpvpaper"
      "noctalia/notes"
      "noctalia/timer"
      "noctalia/translator"
      "noctalia/kaomoji"
      "noctalia/wallhaven"
      "noctalia/world_clock"
      "oldirtty/color_picker"
      "gabrielnathan929/myanimelist"
      "gabrielnathan929/controlfreak"
    ];

    source = [
      {
        name = "official";
        kind = "git";
        location = "https://github.com/gabrielnathan929/official-plugins";
        auto_update = false;
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
