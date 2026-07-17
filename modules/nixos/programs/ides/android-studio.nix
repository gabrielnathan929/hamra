{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.ides."android-studio";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.ides."android-studio" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Android Studio.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [android-studio]);
}
