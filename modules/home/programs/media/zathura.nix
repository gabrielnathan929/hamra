{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.media.zathura;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.media.zathura = mkOption {
    type = types.bool;
    default = false;
    description = "Enable zathura PDF viewer.";
  };

  config.home.packages = mkIf cfg [pkgs.zathura];
}
