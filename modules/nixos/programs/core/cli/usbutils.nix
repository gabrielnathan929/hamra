{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.usbutils;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.usbutils = mkOption {
    type = types.bool;
    default = true;
    description = "Enable usbutils (lsusb).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.usbutils];
}
