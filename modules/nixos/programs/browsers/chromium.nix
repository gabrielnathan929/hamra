{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.browsers.chromium;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.browsers.chromium = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Chromium.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.chromium];
}
