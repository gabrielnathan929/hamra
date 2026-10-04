{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.packaging.gearlever;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.packaging.gearlever = mkOption {
    type = types.bool;
    default = false;
    description = "Enable GearLever (AppImage manager). Downloaded AppImages run through the appimage support toggle (binfmt + appimage-run).";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.gearlever
  ];
}
