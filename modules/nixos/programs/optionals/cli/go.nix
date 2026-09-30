{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.go;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.go = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Golang.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.go];
}
