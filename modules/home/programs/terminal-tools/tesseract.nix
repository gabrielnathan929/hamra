{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.tesseract;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminal-tools.tesseract = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Tesseract OCR.";
  };

  config.home.packages = mkIf cfg [pkgs.tesseract];
}
