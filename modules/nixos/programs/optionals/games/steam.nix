{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.steam;
  games = config.hamra.programs.optionals.games;
  inherit (lib) mkOption mkIf types optional;
in {
  options.hamra.programs.optionals.games.steam = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Steam with hardware acceleration.";
  };

  config.programs.steam = mkIf cfg {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [proton-ge-bin];
    extraPackages = with pkgs;
      [
        gperftools
        libgcc
        pipewire
      ]
      ++ optional games.mangohud mangohud
      ++ optional games.gamemode gamemode
      ++ optional games.gamescope gamescope;
  };
}
