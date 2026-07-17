{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.noctalia.hyprpicker;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.noctalia.hyprpicker = mkOption {
    type = types.bool;
    default = true;
    description = "Enable hyprpicker (color picker, Noctalia plugin dependency).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.hyprpicker];
}
