{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.media.mpv;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.media.mpv = mkOption {
    type = types.bool;
    default = false;
    description = "Enable mpv video player.";
  };

  config.home.packages = mkIf cfg [pkgs.mpv];
}
