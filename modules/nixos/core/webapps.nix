{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.hamra.webapps;

  mkWebapp = name: app: let
    wrapper = pkgs.writeShellScriptBin name ''
      exec ${lib.getExe config.hamra.env.browser} --app=${lib.escapeShellArg app.url} --class=${lib.escapeShellArg name} "$@"
    '';

    desktop = pkgs.makeDesktopItem {
      inherit name;
      inherit (app) desktopName comment categories;
      exec = "${name} %U";
      icon = name;
      startupWMClass = name;
    };

    iconPackage =
      if app.icon == null || app.iconHash == null
      then []
      else [
        (pkgs.runCommand "${name}-icon" {} ''
          mkdir -p $out/share/icons/hicolor/512x512/apps
          cp ${pkgs.fetchurl {
            url = app.icon;
            hash = app.iconHash;
          }} $out/share/icons/hicolor/512x512/apps/${name}.png
        '')
      ];
  in
    [wrapper desktop] ++ iconPackage;
in {
  options.hamra.webapps = mkOption {
    type = types.attrsOf (types.submodule ({name, ...}: {
      options = {
        url = mkOption {
          type = types.str;
          description = "URL opened in the web app window.";
        };
        desktopName = mkOption {
          type = types.str;
          default = name;
          description = "Name shown in the applications menu.";
        };
        comment = mkOption {
          type = types.str;
          default = "Web app opened in its own browser window.";
          description = "Comment shown in the applications menu.";
        };
        categories = mkOption {
          type = types.listOf types.str;
          default = ["Network"];
          description = "Desktop entry categories.";
        };
        icon = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "URL of a 512x512 PNG used as icon.";
        };
        iconHash = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "SRI hash (sha256-...) of the icon.";
        };
      };
    }));
    default = {};
    example = {
      notion = {
        url = "https://www.notion.so";
        desktopName = "Notion";
      };
    };
    description = "Web apps: wrapper + desktop entry that open the site in its own window on the default browser.";
  };

  config.environment.systemPackages = lib.concatLists (lib.mapAttrsToList mkWebapp cfg);
}
