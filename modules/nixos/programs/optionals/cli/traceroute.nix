{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.traceroute;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.traceroute = mkOption {
    type = types.bool;
    default = false;
    description = "Enable traceroute.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.traceroute];
}
