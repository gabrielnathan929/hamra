{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.media.spotube;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.media.spotube = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Spotube.";
  };

  config.environment.systemPackages = mkIf (cfg && !config.hamra.programs.optionals.media.spicetify) [
    pkgs.spotube
  ];
}
