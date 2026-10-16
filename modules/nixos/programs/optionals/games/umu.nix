{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.umu;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.umu = mkOption {
    type = types.bool;
    default = false;
    description = "Enable umu-launcher (Proton runner outside Steam for Windows installers and games).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [umu-launcher]);
}
