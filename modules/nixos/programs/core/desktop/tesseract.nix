{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.desktop.tesseract;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.desktop.tesseract = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Tesseract OCR.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.tesseract];
}
