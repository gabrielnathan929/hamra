{
  config,
  lib,
  ...
}: {
  hamra.theme = lib.mkIf (config.hamra.theme.name == "fullmetal-alchemist") {
    wallpaper = ./wallpapers/wallpaper.jpg;
    profileIcon = ./icons/profile.jpg;
  };
}
