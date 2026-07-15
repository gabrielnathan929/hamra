{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminal-tools.ocr-screenshot;
  inherit (lib) mkOption mkIf types;

  ocr-screenshot = pkgs.writeShellScriptBin "ocr-screenshot" ''
    grim -g "$(slurp)" - |
      tesseract stdin stdout -l por --psm 6 2>/dev/null |
      wl-copy
  '';
in {
  options.hamra.home.programs.terminal-tools.ocr-screenshot = mkOption {
    type = types.bool;
    default = false;
    description = "Enable OCR screenshot script (grim + tesseract + wl-copy).";
  };

  config.home.packages = mkIf cfg [ocr-screenshot];
}
