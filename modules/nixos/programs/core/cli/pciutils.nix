{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.pciutils;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.pciutils = mkOption {
    type = types.bool;
    default = true;
    description = "Enable pciutils (lspci).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.pciutils];
}
