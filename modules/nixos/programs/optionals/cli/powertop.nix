{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.powertop;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.powertop = mkOption {
    type = types.bool;
    default = false;
    description = "Enable powertop (battery and power consumption diagnostics).";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.powertop
  ];
}
