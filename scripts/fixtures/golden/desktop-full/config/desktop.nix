{pkgs, ...}: {
  hamra = {
    desktop = {
      default = "hyprland";
    };

    displayManager = {
      default = "sddm";
      sddm = {
        preset = "catppuccin-mocha";
        theme = "silent";
      };
    };

    displays = {
      headless = {
        "HEADLESS-1" = {
          mode = "1920x1080@60";
          position = "1920x0";
          scale = 1.0;
        };
      };
      physical = {
        "eDP-1" = {
          mode = "1920x1080";
          position = "0x0";
          scale = 1.0;
        };
      };
      virtual = {};
    };

    env = {
      editor = pkgs.neovim;
      browser = pkgs.chromium;
      terminal = pkgs.foot;
      filemanager = pkgs.thunar;
    };

    mise = {
      env = {};
      settings = {
        github_attestations = false;
      };
      tools = {
        gh = "latest";
        go = "latest";
        "npm:@opencode/cli" = "latest";
      };
    };

    flatpak.apps = [];

    packages.extra = [];

    webapps = {
      github = {
        desktopName = "GitHub";
        url = "https://github.com";
      };
    };
  };
}
