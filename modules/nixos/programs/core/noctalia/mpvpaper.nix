{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.noctalia.mpvpaper;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.noctalia.mpvpaper = mkOption {
    type = types.bool;
    default = true;
    description = "Enable mpvpaper (mpv-based wallpaper, Noctalia plugin dependency).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.mpvpaper];
}
