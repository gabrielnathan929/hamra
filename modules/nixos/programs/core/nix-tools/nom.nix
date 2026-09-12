{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.nix-tools.nom;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.nix-tools.nom = mkOption {
    type = types.bool;
    default = true;
    description = "Enable nix-output-monitor (nom).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.nix-output-monitor];
}
