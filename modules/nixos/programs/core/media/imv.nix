{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.media.imv;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.media.imv = mkOption {
    type = types.bool;
    default = true;
    description = "Enable imv image viewer.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.imv];
}
