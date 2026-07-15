{
  lib,
  themesDir,
  ...
}: let
  themes = import ../../../../modules/nixos/core/theme/themes/themes-list.nix;
in {
  home.file = builtins.listToAttrs (
    lib.flatten [
      (map (theme: {
          name = "noctalia/wallpapers/${theme}.jpg";
          value = {
            source = "${themesDir}/${theme}/wallpapers/wallpaper.jpg";
            force = true;
          };
        })
        themes)
      (map (theme: {
          name = "noctalia/avatars/${theme}.jpg";
          value = {
            source = "${themesDir}/${theme}/icons/profile.jpg";
            force = true;
          };
        })
        themes)
    ]
  );
}
