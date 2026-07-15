{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.ripgrep;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.ripgrep = mkOption {
    type = types.bool;
    default = false;
    description = "Enable ripgrep (rg).";
  };

  config.home.packages = mkIf cfg [pkgs.ripgrep];
}
