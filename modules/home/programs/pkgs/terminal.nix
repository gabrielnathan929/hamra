{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.pkgs.terminal;
  inherit (lib) mkOption mkIf types;

  ocr-screenshot = pkgs.writeShellScriptBin "ocr-screenshot" ''
    TMPDIR=$(mktemp -d)
    cd "$TMPDIR"
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" screenshot.png
    ${pkgs.tesseract}/bin/tesseract screenshot.png stdout | ${pkgs.wl-clipboard}/bin/wl-copy
    rm -rf "$TMPDIR"
  '';
in {
  options.hamra.home.programs.pkgs.terminal = mkOption {
    type = types.bool;
    default = true;
    description = "Enable terminal utility packages (tmux, eza, btop).";
  };

  config.home.packages = mkIf cfg (with pkgs; [
    tmux
    eza
    btop
    tree
    curl
    wget
    zip
    unzip
    fastfetch
    tesseract
    wl-clipboard
    grim
    slurp
  ]);
}
