{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.media.mpv;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.media.mpv = mkOption {
    type = types.bool;
    default = true;
    description = "Enable mpv media player.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.mpv];
}
