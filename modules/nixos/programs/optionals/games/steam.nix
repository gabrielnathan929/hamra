{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.steam;
  inherit (lib) mkOption mkIf types;
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
    extraPackages = with pkgs; [
      gperftools
      libgcc
      pipewire
    ];
  };
}
