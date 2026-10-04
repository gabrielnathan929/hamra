{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.cli.imagemagick;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.cli.imagemagick = mkOption {
    type = types.bool;
    default = false;
    description = "Enable ImageMagick.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.imagemagick];
}
