{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "resident-evil") {
    wallpaper = ./wallpapers/resident-evil-01.jpg;
    profileIcon = ./icons/resident-evil-profile-1.jpg;
    videosDir = ./videos;
  };
}
