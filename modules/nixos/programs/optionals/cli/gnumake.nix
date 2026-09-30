{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.gnumake;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.gnumake = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GNU Make.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gnumake];
}
