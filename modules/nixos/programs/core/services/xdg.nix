{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.services.xdg;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
  browserDesktops = [
    {
      package = pkgs.chromium;
      desktop = "chromium-browser.desktop";
    }
    {
      package = pkgs.firefox;
      desktop = "firefox.desktop";
    }
    {
      package = pkgs.google-chrome;
      desktop = "google-chrome.desktop";
    }
    {
      package = pkgs.helium;
      desktop = "helium.desktop";
    }
  ];
  defaultBrowser = lib.findFirst (browser: config.hamra.env.browser == browser.package) null browserDesktops;
in {
  options.hamra.programs.core.services.xdg = mkOption {
    type = types.bool;
    default = true;
    description = "Configure XDG user directories and MIME associations.";
  };

  config = mkIf cfg {
    environment.systemPackages = [
      pkgs.gvfs
    ];

    home-manager.users.${userName}.xdg.mimeApps = mkIf (defaultBrowser != null) {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = defaultBrowser.desktop;
        "x-scheme-handler/https" = defaultBrowser.desktop;
      };
    };
  };
}
