{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.chromium;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.chromium = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Chromium.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.chromium];
}
