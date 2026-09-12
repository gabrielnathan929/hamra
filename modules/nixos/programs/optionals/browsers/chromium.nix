{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.browsers.chromium;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.browsers.chromium = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Chromium.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.chromium];
}
