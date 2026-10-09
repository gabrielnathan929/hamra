{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "dragon-ball") {
    wallpaper = ./wallpapers/dragon-ball-1.jpg;
    profileIcon = ./icons/dragon-ball-profile-1.jpg;
    videosDir = ./videos;
  };
}
