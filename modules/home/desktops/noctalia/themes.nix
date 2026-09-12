{
  lib,
  themesDir,
  ...
}: let
  themes = import ../../../../modules/nixos/core/theme/themes/themes-list.nix;
in {
  home.file = builtins.listToAttrs (
    lib.flatten [
      (map (theme: let
        wallpaperFiles = builtins.attrNames (
          builtins.readDir "${themesDir}/${theme}/wallpapers"
        );
      in
        map (file: {
          name = "noctalia/wallpapers/${file}";
          value = {
            source = "${themesDir}/${theme}/wallpapers/${file}";
            force = true;
          };
        })
        wallpaperFiles)
      themes)
      (map (theme: let
        iconFiles = builtins.attrNames (
          builtins.readDir "${themesDir}/${theme}/icons"
        );
      in
        map (file: {
          name = "noctalia/avatars/${file}";
          value = {
            source = "${themesDir}/${theme}/icons/${file}";
            force = true;
          };
        })
        iconFiles)
      themes)
      (map (theme: let
        videoFiles = builtins.attrNames (
          builtins.readDir "${themesDir}/${theme}/videos"
        );
      in
        map (file: {
          name = "noctalia/videos/${file}";
          value = {
            source = "${themesDir}/${theme}/videos/${file}";
            force = true;
          };
        })
        videoFiles)
      themes)
    ]
  );
}
