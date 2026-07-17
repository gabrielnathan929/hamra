{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.development.gnumake;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.development.gnumake = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GNU Make.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gnumake];
}
