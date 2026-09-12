{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.lutris;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.lutris = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Lutris (game manager for Linux/Windows games) with Wine support.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [lutris winetricks wineWow64Packages.stable];
  };
}
