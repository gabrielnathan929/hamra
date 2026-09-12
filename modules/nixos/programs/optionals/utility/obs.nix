{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.utility.obs;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.utility.obs = mkOption {
    type = types.bool;
    default = false;
    description = "Enable OBS Studio.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.obs-studio];
}
