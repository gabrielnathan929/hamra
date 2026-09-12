{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.desktop."ocr-screenshot";
  inherit (lib) mkOption mkIf types;

  ocr-screenshot = pkgs.writeShellScriptBin "ocr-screenshot" ''
    grim -g "$(slurp)" - |
      tesseract stdin stdout -l por --psm 6 2>/dev/null |
      wl-copy
  '';
in {
  options.hamra.programs.core.desktop."ocr-screenshot" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable OCR screenshot script (grim + tesseract + wl-copy).";
  };

  config.environment.systemPackages = mkIf cfg [ocr-screenshot];
}
