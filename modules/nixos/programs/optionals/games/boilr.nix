{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.boilr;
  games = config.hamra.programs.optionals.games;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.boilr = mkOption {
    type = types.bool;
    default = false;
    description = "Enable BoilR (imports non-Steam games into Steam with artwork from SteamGridDB, auto-enabled with Steam).";
  };

  config.environment.systemPackages = mkIf (cfg || games.steam) (with pkgs; [boilr]);
}
