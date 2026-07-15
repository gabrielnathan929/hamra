{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.nix-tools.nix-search;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.nix-tools.nix-search = mkOption {
    type = types.bool;
    default = false;
    description = "Enable nix-search CLI.";
  };

  config.home.packages = mkIf cfg [pkgs.nix-search-cli];
}
