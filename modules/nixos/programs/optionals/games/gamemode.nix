{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.gamemode;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.gamemode = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GameMode (Feral's on-demand performance daemon, activated by games that request it).";
  };

  config.programs.gamemode.enable = mkIf cfg true;
}
