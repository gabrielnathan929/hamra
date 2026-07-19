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

    env = {
      editor = pkgs.neovim;
      browser = pkgs.helium;
      terminal = pkgs.foot;
      filemanager = pkgs.thunar;
    };

    mobile.android = true;

    programs = {
      optionals = {
        virtualisation.boxes = true;

        packaging = {
          flatpak = true;
          gnome-software = true;
        };

        productivity = {
          obsidian = true;
          office = true;
        };

        audio = {
          spotify = true;
          spicetify = true;
        };

        remote.remmina = true;

        utility = {
          localsend = true;
          obs = true;
        };

        services.wayvnc = false;

        games = {
          steam = true;
          pcsx2 = true;
          heroic = true;
        };

        media.kodi = true;

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

        development = {
          docker = true;
          go = true;
          jdk = true;
          "docker-compose" = true;
          gcc = true;
          gnumake = true;
          lazydocker = true;
          lazygit = true;
          nodejs = true;
          python3 = true;
          ripgrep = true;
        };
      };

      core = {
        development = {
          git = true;
          opencode = true;
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

      hamra.home.programs = {};
    };
  };
}
