{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui."android-studio";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui."android-studio" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Android Studio.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [android-studio]);
}
