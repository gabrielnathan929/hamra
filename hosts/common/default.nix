{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  hamraLib = import ../../modules/lib {inherit lib;};
in {
  hamra = lib.mkDefault {
    env = {
      editor = pkgs.neovim;
      browser = pkgs.chromium;
      terminal = pkgs.foot;
      filemanager = pkgs.thunar;
    };

    packages.extra = [];

    mise = {
      tools = {
        codex = "latest";
        copilot = "latest";
        gh = "latest";
        go = "latest";
        java = "latest";
        opencode = "latest";
        python = "latest";

        "github:herdrdev/herdr" = "latest";
        "github:google-antigravity/antigravity-cli" = "latest";
      };

      settings = {
        github_attestations = false;

        python = {
          compile = false;
        };
      };
    };

    mobile.android = false;

    programs = {
      core.gui.thunar = true;

      optionals = {
        gui = {
          android-studio = true;
          bitwarden = true;
          boxes = false;
          brmodelo = true;
          bruno = true;
          chromium = true;
          camunda-modeler = true;
          dbeaver = true;
          discord = true;
          drawio = true;
          ente-auth = true;
          firefox = false;
          google-chrome = false;
          helium = true;
          insomnia = true;
          intellij = true;
          localsend = true;
          mongodb-compass = true;
          nautilus = true;
          netbeans = true;
          notion = true;
          obsidian = true;
          office = true;
          postman = true;
          pycharm = true;
          remmina = true;
          upscayl = true;
          keepassxc = false;
          vesktop = false;
          virt-manager = true;
          vscode = true;
          wireshark = false;
        };

        tui = {
          cliamp = true;
          lazydocker = true;
          lazygit = true;
          yazi = true;
        };

        cli = {
          gcc = true;
          ffmpeg = true;
          imagemagick = true;
          inetutils = true;
          mtr = true;
          strace = true;
          traceroute = true;
          gnumake = true;
          go = true;
          jdk = true;
          nodejs = true;
          powertop = true;
          python3 = true;
          rclone = true;
          ripgrep = true;
        };

        media = {
          "davinci-resolve" = true;
          kodi = true;
          obs = true;
          qbittorrent = true;
          spicetify = true;
          spotify = true;
        };

        services = {
          appimage = true;
          docker = true;
          "docker-compose" = true;
          samba = false;
          wayvnc = true;
          tigervnc = false;
        };

        games = {
          gamemode = true;
          gamepad = true;
          gamescope = true;
          heroic = true;
          hydralauncher = true;
          lutris = true;
          mangohud = true;
          pcsx2 = true;
          steam = true;
        };

        packaging = {
          flatpak = true;
          gearlever = true;
          gnome-software = true;
          nix-software-center = true;
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
        tui = {
          tmux = true;
          herdr = true;
        };
      };
    };
  };
}
