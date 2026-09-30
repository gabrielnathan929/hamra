{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.rclone;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.rclone = mkOption {
    type = types.bool;
    default = false;
    description = "Enable rclone (cloud sync: OneDrive/Google Drive).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.rclone];
}
