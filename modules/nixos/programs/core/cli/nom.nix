{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.nom;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.nom = mkOption {
    type = types.bool;
    default = true;
    description = "Enable nix-output-monitor (nom).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.nix-output-monitor];
}
