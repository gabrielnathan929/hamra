{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.hydralauncher;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.hydralauncher = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Hydra Launcher (game launcher with embedded bittorrent client).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [hydralauncher]);
}
