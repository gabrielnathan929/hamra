{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.upscayl;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.upscayl = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Upscayl (AI image upscaler).";
  };

  config.environment.systemPackages = mkIf cfg [
    pkgs.upscayl
  ];
}
