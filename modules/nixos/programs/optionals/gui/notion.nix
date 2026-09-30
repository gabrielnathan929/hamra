{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.notion;
  inherit (lib) mkOption mkIf types;

  notion-desktop = pkgs.makeDesktopItem {
    name = "notion";
    desktopName = "Notion";
    exec = "notion %U";
    icon = "notion";
    comment = "Workspace de notas, docs e tarefas";
    categories = ["Office" "Network"];
    startupWMClass = "notion";
  };

  notion = pkgs.writeShellScriptBin "notion" ''
    exec ${lib.getExe config.hamra.env.browser} --app=https://www.notion.so --class=notion "$@"
  '';

  notionIcon = pkgs.fetchurl {
    url = "https://www.notion.so/images/logo-ios.png";
    hash = "sha256-WcQqCv0g3J3Qz1mOEF53SkhL8Qzb7B/8OjPJy1lXm0c=";
  };
in {
  options.hamra.programs.optionals.gui.notion = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Notion como web app do navegador (wrapper que abre o notion.so em janela --app).";
  };

  config.environment.systemPackages = mkIf cfg [
    notion
    notion-desktop
    (pkgs.runCommand "notion-icon" {} ''
      mkdir -p $out/share/icons/hicolor/512x512/apps
      cp ${notionIcon} $out/share/icons/hicolor/512x512/apps/notion.png
    '')
  ];
}
