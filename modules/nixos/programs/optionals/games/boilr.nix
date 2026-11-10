{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.boilr;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.boilr = mkOption {
    type = types.bool;
    default = false;
    description = "Enable BoilR (imports non-Steam games into Steam with artwork from SteamGridDB).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [boilr]);
}
