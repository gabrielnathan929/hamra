{
  config,
  pkgs,
  lib,
  self,
  inputs,
  ...
}: let
  hamraLib = import "${self.outPath}/modules/lib" {inherit lib;};
in {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "vm";

    hardware = {
      gpu = "virtio";
      firmware = "uefi";
    };

    desktop.default = "sway";

    programs = {
      virtualisation.boxes = true;
      packaging.flatpak = true;
      apps.obsidian = true;
      services.wayvnc = false;

      games = {
        steam = true;
        pcsx2 = true;
        heroic = true;
      };

      development = {
        docker = true;
        lazydocker = true;
        lazygit = true;
        opencode = true;
      };

      security = {
        bitwarden = true;
        "ente-auth" = true;
      };

      ides = {
        vscode = true;
        intellij = true;
        pycharm = true;
        android-studio = true;
        dbeaver = true;
        netbeans = true;
      };
    };
  };

  system.stateVersion = "26.05";

  home-manager = {
    extraSpecialArgs = {
      inherit inputs hamraLib;
      wallpaperPath = config.hamra.theme.wallpaper;
      themesDir = ../../modules/nixos/core/theme/themes;
      keyboard = config.hamra.keyboard;
      desktop = config.hamra.desktop.default;
      displays = config.hamra.displays;
      wayvnc = config.hamra.programs.services.wayvnc;
      env = config.hamra.env;
    };
    users.${config.hamra.users.userName} = {
      home.stateVersion = "26.05";
      imports = [../../modules/home];

      hamra.home.programs = {
        git = true;
        xdg = true;
        terminals.foot = true;
        shell = {
          zsh = true;
          starship = true;
          aliases = true;
        };
        media = {
          mpv = true;
          imv = true;
          zathura = true;
        };
        scripts = {
          setup-ssh = true;
          "setup-gpg" = true;
          "flatpak-install" = true;
          "flatpak-remove" = true;
        };
        office = true;
        apps = {
          obsidian = true;
          spotify = true;
          spicetify = true;
          localsend = true;
          gtk = true;
        };
        dev = {
          git = true;
          neovim = true;
          ripgrep = true;
          fd = true;
          jq = true;
          gnumake = true;
          gcc = true;
          nodejs = true;
          python3 = true;
        };
        nix-tools = {
          "nix-search" = true;
          nom = true;
        };
        terminal-tools = {
          tmux = true;
          eza = true;
          btop = true;
          tree = true;
          curl = true;
          wget = true;
          zip = true;
          unzip = true;
          fastfetch = true;
          tesseract = true;
          wl-clipboard = true;
          grim = true;
          slurp = true;
          "ocr-screenshot" = true;
          tigervnc = false;
          remmina = true;
          gum = true;
          fzf = true;
        };
      };
    };
  };
}
