{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "naruto") {
    wallpaper = ./wallpapers/wallpaper.jpg;
    profileIcon = ./icons/profile.jpg;
  };
}
