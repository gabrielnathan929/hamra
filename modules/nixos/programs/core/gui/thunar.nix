{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.gui.thunar;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.gui.thunar = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Thunar.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [thunar]);
}
