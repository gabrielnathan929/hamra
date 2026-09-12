{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.nix-tools."nix-search";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.nix-tools."nix-search" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable nix-search CLI.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.nix-search-cli];
}
