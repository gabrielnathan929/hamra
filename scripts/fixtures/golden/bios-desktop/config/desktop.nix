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
      headless = {};
      physical = {};
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
      settings = {};
      tools = {};
    };

    flatpak.apps = [];

    packages.extra = [];
  };
}
