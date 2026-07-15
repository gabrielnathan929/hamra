{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.games.heroic;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.games.heroic = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Heroic Games Launcher.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [heroic]);
}
