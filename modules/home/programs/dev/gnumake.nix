{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.gnumake;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.gnumake = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GNU Make.";
  };

  config.home.packages = mkIf cfg [pkgs.gnumake];
}
