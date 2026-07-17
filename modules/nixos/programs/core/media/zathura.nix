{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.media.zathura;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.media.zathura = mkOption {
    type = types.bool;
    default = true;
    description = "Enable zathura PDF reader.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.zathura];
}
