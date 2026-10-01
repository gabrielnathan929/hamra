{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.netcat;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.netcat = mkOption {
    type = types.bool;
    default = true;
    description = "Enable netcat.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.netcat];
}
