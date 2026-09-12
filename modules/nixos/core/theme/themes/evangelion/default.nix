{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "evangelion") {
    wallpaper = ./wallpapers/evangelion-01.jpg;
    profileIcon = ./icons/evangelion-profile-1.jpg;
    videosDir = ./videos;
  };
}
