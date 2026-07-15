{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.pkgs.nix;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.pkgs.nix = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Nix tooling packages (nix-search, nom).";
  };

  config.home.packages = mkIf cfg (with pkgs; [
    nix-search-cli
    nix-output-monitor
  ]);
}
