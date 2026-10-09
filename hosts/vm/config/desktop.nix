{pkgs, ...}: {
  hamra = {
    desktop = {
      default = "sway";
    };

    displayManager = {
      default = "sddm";
      sddm = {
        preset = "catppuccin-mocha";
        theme = "silent";
      };
    };

    displays = {
      headless = {};
      physical = {};
      virtual = {
        "Virtual-1" = {
          mode = "1920x1080@60";
          position = "0x0";
          scale = 1.0;
        };
      };
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
        python = {
          compile = false;
        };
      };
      tools = {
        codex = "latest";
        copilot = "latest";
        gh = "latest";
        "github:google-antigravity/antigravity-cli" = "latest";
        "github:herdrdev/herdr" = "latest";
        go = "latest";
        java = "latest";
        "npm:@opencode/cli" = "latest";
        python = "latest";
      };
    };

    flatpak.apps = [];

    packages.extra = [];
  };
}
