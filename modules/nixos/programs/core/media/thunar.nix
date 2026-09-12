{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.media.thunar;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.media.thunar = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Thunar.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [thunar]);
}
