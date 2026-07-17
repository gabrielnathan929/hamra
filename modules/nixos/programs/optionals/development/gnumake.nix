{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.development.gnumake;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.development.gnumake = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GNU Make.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gnumake];
}
