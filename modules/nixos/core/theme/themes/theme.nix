{lib, ...}: {
  options.hamra.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "dragon-ball";
      description = "Hamra theme.";
    };

    wallpaper = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./dragon-ball/wallpapers/dragon-ball-01.jpg;
      description = "Active wallpaper path, defined by the theme.";
    };

    profileIcon = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./dragon-ball/icons/dragon-ball-profile.jpg;
      description = "Active profile avatar path, defined by the theme.";
    };

    videosDir = lib.mkOption {
      type = lib.types.path;
      internal = true;
      default = ./dragon-ball/videos;
      description = "Video directory of the active theme, defined by the theme.";
    };
  };
}
