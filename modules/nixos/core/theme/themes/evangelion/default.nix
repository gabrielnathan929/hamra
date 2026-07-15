{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "evangelion") {
    wallpaper = ./wallpapers/wallpaper.jpg;
    profileIcon = ./icons/profile.jpg;
  };
}
