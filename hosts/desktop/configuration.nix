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

    desktop.default = "hyprland";

    env = {
      editor = pkgs.neovim;
      browser = pkgs.helium;
      terminal = pkgs.foot;
      filemanager = pkgs.nautilus;
    };

    packages.extra = [];

    mobile.android = false;

    programs = {
      optionals = {
        virtualisation = {
          boxes = false;
          virt-manager = false;
        };

        packaging = {
          flatpak = false;
          gnome-software = false;
        };

        productivity = {
          obsidian = false;
          office = false;
          drawio = false;
        };

        audio = {
          spotify = false;
          spicetify = false;
        };

        remote.remmina = true;

        utility = {
          appimage = false;
          localsend = false;
          obs = false;
        };

        services = {
          wayvnc = false;
          samba = true;
        };

        games = {
          steam = false;
          pcsx2 = false;
          heroic = false;
          lutris = false;
          hydralauncher = false;
        };

        media = {
          kodi = false;
          nautilus = false;
          qbittorrent = false;
        };

        communication.discord = false;

        security = {
          bitwarden = true;
          "ente-auth" = true;
        };

        ides = {
          vscode = true;
          intellij = false;
          pycharm = false;
          android-studio = false;
          dbeaver = false;
          netbeans = false;
          bruno = false;
          mongodb-compass = false;
          postman = false;
          insomnia = false;
          camunda-modeler = false;
          brmodelo = false;
        };

        development = {
          docker = false;
          go = false;
          jdk = false;
          "docker-compose" = false;
          gcc = false;
          gnumake = false;
          lazydocker = false;
          lazygit = false;
          nodejs = false;
          python3 = false;
          ripgrep = false;
        };
      };

      core = {
        development = {
          git = true;
          opencode = true;
        };

        noctalia = {
          "gpu-screen-recorder" = true;
          evtest = true;
          mpvpaper = true;
          hyprpicker = true;
          "translate-shell" = true;
        };
      };
    };
  };

  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";

  home-manager = {
    extraSpecialArgs = {
      inherit inputs hamraLib;
      wallpaperPath = config.hamra.theme.wallpaper;
      themesDir = ../../modules/nixos/core/theme/themes;
      keyboard = config.hamra.keyboard;
      desktop = config.hamra.desktop.default;
      displays = config.hamra.displays;
      wayvnc = config.hamra.programs.optionals.services.wayvnc;
      env = config.hamra.env;
    };
    users.${config.hamra.users.userName} = {
      home.stateVersion = "26.05";
      imports = [../../modules/home];

      hamra.home.programs = {
        editors.neovim = true;
      };
    };
  };
}
