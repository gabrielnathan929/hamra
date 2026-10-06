{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.games.gamepad;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.gamepad = mkOption {
    type = types.bool;
    default = false;
    description = "Enable udev rules for game controllers (DualShock, DualSense, Xbox and others).";
  };

  config.services.udev.packages = mkIf cfg [
    pkgs.game-devices-udev-rules
  ];
}
