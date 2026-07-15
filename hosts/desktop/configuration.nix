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
    networking.hostname = "desktop";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "niri";

    programs = {
      virtualisation = {
        boxes = false;
        virt-manager = true;
      };
      packaging.flatpak = true;
      apps.obsidian = true;
      services.btop = true;
      services.wayvnc = false;

      games = {
        steam = true;
        pcsx2 = true;
        heroic = true;
      };

      development = {
        docker = true;
        "docker-compose" = true;
        lazydocker = true;
        lazygit = true;
        opencode = true;
      };

      security = {
        bitwarden = false;
        "ente-auth" = true;
      };

      ides = {
        vscode = true;
        intellij = true;
        pycharm = true;
        android-studio = false;
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
        };
        scripts = {
          setup-ssh = true;
          "setup-gpg" = true;
          "flatpak-install" = true;
          "flatpak-remove" = true;
        };
        office = true;
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
        apps = {
          obsidian = true;
          spotify = true;
          spicetify = true;
          localsend = true;
          gtk = true;
        };
        nix-tools = {
          "nix-search" = true;
          nom = true;
        };
      };
    };
  };
}
