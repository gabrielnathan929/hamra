{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "studio-ghibli") {
    wallpaper = ./wallpapers/wallpaper.jpg;
    profileIcon = ./icons/profile.jpg;
  };
}
