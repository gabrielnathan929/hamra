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
      filemanager = pkgs.nautilus;
    };

    packages.extra = [];

    mobile.android = false;

    programs.optionals = {
      gui = {
        android-studio = true;
        bitwarden = true;
        boxes = true;
        brmodelo = true;
        bruno = true;
        chromium = true;
        camunda-modeler = true;
        dbeaver = true;
        discord = true;
        drawio = true;
        ente-auth = true;
        firefox = true;
        google-chrome = true;
        helium = true;
        insomnia = true;
        intellij = true;
        localsend = true;
        mongodb-compass = true;
        nautilus = true;
        netbeans = true;
        obsidian = true;
        office = true;
        postman = true;
        pycharm = true;
        remmina = true;
        keepassxc = true;
        vesktop = true;
        virt-manager = true;
        vscode = true;
      };

      tui = {
        antigravity = true;
        clamp = true;
        codex = true;
        lazydocker = true;
        lazygit = true;
        opencode = true;
        yazi = true;
      };

      cli = {
        gcc = true;
        gnumake = true;
        go = true;
        jdk = true;
        nodejs = true;
        python3 = true;
        rclone = true;
        ripgrep = true;
      };

      media = {
        kodi = true;
        obs = true;
        qbittorrent = true;
        spicetify = true;
        spotify = true;
        spotube = true;
      };

      services = {
        appimage = true;
        docker = true;
        "docker-compose" = true;
        samba = true;
        wayvnc = true;
        tigervnc = true;
      };

      games = {
        heroic = true;
        hydralauncher = true;
        lutris = true;
        moonlight-qt = true;
        pcsx2 = true;
        steam = true;
      };

      packaging = {
        flatpak = true;
        gnome-software = true;
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
