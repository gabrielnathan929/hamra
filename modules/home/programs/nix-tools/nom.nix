{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.nix-tools.nom;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.nix-tools.nom = mkOption {
    type = types.bool;
    default = false;
    description = "Enable nix-output-monitor (nom).";
  };

  config.home.packages = mkIf cfg [pkgs.nix-output-monitor];
}
