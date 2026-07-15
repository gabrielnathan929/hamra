{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "lazarus") {
    wallpaper = ./wallpapers/wallpaper.jpg;
    profileIcon = ./icons/profile.jpg;
  };
}
