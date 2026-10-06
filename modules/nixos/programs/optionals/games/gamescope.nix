{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.gamescope;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.gamescope = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Gamescope (Valve's micro compositor for games, usable from Steam launch options).";
  };

  config.programs.gamescope.enable = mkIf cfg true;
}
