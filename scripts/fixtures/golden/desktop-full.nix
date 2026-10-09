{
  config,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/nixos/core
    ../../modules/nixos/desktops
    ../../modules/nixos/programs
    ./hardware-configuration.nix
  ];

  hamra = {
    networking.hostname = "test-desktop";

    users.userName = "tester";

    locale = "en_US.UTF-8";

    timezone = "UTC";

    theme.name = "dragon-ball";

    hardware = {
      bluetooth = true;
      brightness = true;
      firmware = "uefi";
      gpu = "intel";
      touchpad = true;
    };

    keyboard = {
      keymap = "br";
      xkbVariant = "abnt2";
    };

    audio = {
      default = "pipewire";
    };

    boot = {
      grub = {
        device = "/dev/sda";
        useOSProber = false;
      };
      loader = "systemd-boot";
      systemd = {
        editor = false;
      };
    };

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

    gc = {
      enable = true;
      keepDays = 30;
      maxGenerations = 20;
      schedule = "weekly";
    };

    mobile = {
      android = false;
    };

    printing = true;

    services = {
      gnupg = true;
      keyring = true;
      polkit = true;
      sshd = true;
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

    programs.core = {
      cli = {
        bat = true;
        curl = true;
        dnsutils = true;
        duf = true;
        eza = true;
        fd = true;
        file = true;
        gh = true;
        git = true;
        grim = true;
        jq = true;
        lsof = true;
        mise = true;
        netcat = true;
        "nix-search" = true;
        nom = true;
        "ocr-screenshot" = true;
        p7zip = true;
        pciutils = true;
        psmisc = true;
        rsync = true;
        slurp = true;
        tesseract = true;
        "trash-cli" = true;
        tree = true;
        unrar = true;
        unzip = true;
        usbutils = true;
        wget = true;
        "wl-clipboard" = true;
        yq = true;
        zip = true;
        zoxide = true;
      };
      gui = {
        imv = true;
        mpv = true;
        thunar = false;
        zathura = true;
      };
      noctalia = {
        evtest = true;
        "gpu-screen-recorder" = true;
        hyprpicker = true;
        mpvpaper = true;
        "translate-shell" = true;
      };
      scripts = {
        apps = true;
        keybinds = true;
        "setup-nas" = true;
      };
      services = {
        gtk = true;
        xdg = true;
      };
      tui = {
        btop = true;
        fzf = false;
        ncdu = true;
        tmux = true;
      };
    };

    programs.optionals = {
      cli = {
        ffmpeg = false;
        gcc = false;
        gnumake = false;
        go = false;
        imagemagick = false;
        inetutils = false;
        jdk = false;
        mtr = false;
        nodejs = false;
        powertop = false;
        python3 = false;
        rclone = false;
        ripgrep = false;
        strace = false;
        traceroute = false;
      };
      games = {
        gamemode = false;
        gamepad = false;
        gamescope = false;
        heroic = false;
        hydralauncher = false;
        lutris = false;
        mangohud = false;
        pcsx2 = false;
        steam = false;
      };
      gui = {
        "android-studio" = false;
        bitwarden = false;
        boxes = false;
        brmodelo = false;
        bruno = false;
        "camunda-modeler" = false;
        chromium = true;
        dbeaver = false;
        discord = false;
        drawio = false;
        "ente-auth" = false;
        firefox = false;
        "google-chrome" = false;
        helium = false;
        insomnia = false;
        intellij = false;
        keepassxc = false;
        localsend = false;
        "mongodb-compass" = false;
        nautilus = false;
        netbeans = false;
        notion = false;
        obsidian = false;
        office = false;
        postman = false;
        pycharm = false;
        remmina = false;
        upscayl = false;
        vesktop = false;
        "virt-manager" = false;
        vscode = false;
        wireshark = false;
      };
      media = {
        "davinci-resolve" = false;
        kodi = false;
        obs = false;
        qbittorrent = false;
        spicetify = false;
        spotify = false;
      };
      packaging = {
        flatpak = false;
        gearlever = false;
        "gnome-software" = false;
        "nix-software-center" = false;
      };
      services = {
        appimage = false;
        docker = false;
        "docker-compose" = false;
        samba = false;
        tigervnc = false;
        wayvnc = true;
      };
      tui = {
        cliamp = false;
        lazydocker = false;
        lazygit = false;
        yazi = false;
      };
    };
  };

  home-manager.users.${config.hamra.users.userName}.hamra.home.programs = {
    editors = {
      neovim = false;
    };
    shell = {
      aliases = true;
      starship = true;
      zsh = true;
    };
    terminals = {
      alacritty = false;
      foot = true;
      kitty = false;
    };
    tui = {
      herdr = false;
      tmux = true;
    };
    utils = {
      fastfetch = false;
    };
  };
}
