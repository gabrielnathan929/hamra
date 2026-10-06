{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.mangohud;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.mangohud = mkOption {
    type = types.bool;
    default = false;
    description = "Enable MangoHud (FPS and performance overlay for games, works with mangohud %command% on Steam).";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.mangohud
  ];
}
