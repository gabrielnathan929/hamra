{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.notion;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.notion = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Notion como web app do navegador (wrapper que abre o notion.so em janela --app).";
  };

  config = mkIf cfg {
    hamra.webapps.notion = {
      url = "https://www.notion.so";
      desktopName = "Notion";
      comment = "Workspace de notas, docs e tarefas";
      categories = ["Office" "Network"];
      icon = "https://www.notion.so/images/logo-ios.png";
      iconHash = "sha256-WcQqCv0g3J3Qz1mOEF53SkhL8Qzb7B/8OjPJy1lXm0c=";
    };
  };
}
