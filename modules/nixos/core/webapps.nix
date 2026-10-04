{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  cfg = config.hamra.webapps;

  urlParts = url: let
    noFragment = builtins.head (lib.splitString "#" url);
    noQuery = builtins.head (lib.splitString "?" noFragment);
    noScheme = lib.removePrefix "https://" (lib.removePrefix "http://" noQuery);
    segments = lib.splitString "/" noScheme;
    authority = builtins.head segments;
  in {
    host = lib.toLower (lib.last (lib.splitString "@" authority));
    path = lib.removeSuffix "/" (lib.concatStringsSep "/" (builtins.tail segments));
  };

  derivedWmClass = url: let
    inherit (urlParts url) host path;
  in "chrome-${host}__${path}-Default";

  mkWebapp = name: app: let
    wrapper = pkgs.writeShellScriptBin name ''
      exec ${lib.getExe config.hamra.env.browser} --app=${lib.escapeShellArg app.url} --class=${lib.escapeShellArg name} "$@"
    '';

    desktop = pkgs.makeDesktopItem {
      inherit name;
      inherit (app) desktopName comment categories;
      exec = "${name} %U";
      icon = name;
      startupWMClass =
        if app.startupWMClass != null
        then app.startupWMClass
        else derivedWmClass app.url;
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
        startupWMClass = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Window class of the web app window, used to match it with this desktop entry. Defaults to the class Chromium derives from the URL (chrome-<host>__<path>-Default); set it explicitly for other browsers or unusual URLs.";
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
