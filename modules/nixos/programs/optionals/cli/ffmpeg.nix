{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.ffmpeg;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.ffmpeg = mkOption {
    type = types.bool;
    default = false;
    description = "Enable FFmpeg.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.ffmpeg];
}
