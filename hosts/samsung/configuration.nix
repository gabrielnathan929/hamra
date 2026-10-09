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
    networking.hostname = "samsung";

    users.userName = "gabrielnathan";

    locale = "pt_BR.UTF-8";

    timezone = "America/Sao_Paulo";

    theme.name = "dragon-ball";

    hardware = {
      bluetooth = true;
      brightness = true;
      firmware = "uefi";
      gpu = "intel";
      touchpad = true;
    };

    keyboard = {
      keymap = "us";
      xkbVariant = "intl";
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
        fzf = true;
        ncdu = true;
        tmux = true;
      };
    };

    programs.optionals = {
      cli = {
        ffmpeg = true;
        gcc = true;
        gnumake = true;
        go = true;
        imagemagick = true;
        inetutils = true;
        jdk = true;
        mtr = true;
        nodejs = true;
        powertop = true;
        python3 = true;
        rclone = true;
        ripgrep = true;
        strace = true;
        traceroute = true;
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
      gui = {
        "android-studio" = true;
        bitwarden = true;
        boxes = true;
        brmodelo = true;
        bruno = true;
        "camunda-modeler" = true;
        chromium = true;
        dbeaver = true;
        discord = true;
        drawio = true;
        "ente-auth" = true;
        firefox = true;
        "google-chrome" = true;
        helium = true;
        insomnia = true;
        intellij = true;
        keepassxc = true;
        localsend = true;
        "mongodb-compass" = true;
        nautilus = true;
        netbeans = true;
        notion = true;
        obsidian = true;
        office = true;
        postman = true;
        pycharm = true;
        remmina = true;
        upscayl = true;
        vesktop = true;
        "virt-manager" = true;
        vscode = true;
        wireshark = true;
      };
      media = {
        "davinci-resolve" = true;
        kodi = true;
        obs = true;
        qbittorrent = true;
        spicetify = true;
        spotify = true;
      };
      packaging = {
        flatpak = true;
        gearlever = true;
        "gnome-software" = true;
        "nix-software-center" = true;
      };
      services = {
        appimage = true;
        docker = true;
        "docker-compose" = true;
        samba = false;
        tigervnc = false;
        wayvnc = true;
      };
      tui = {
        cliamp = true;
        lazydocker = true;
        lazygit = true;
        yazi = true;
      };
    };
  };

  home-manager.users.${config.hamra.users.userName}.hamra.home.programs = {
    editors = {
      neovim = true;
    };
    shell = {
      aliases = true;
      starship = true;
      zsh = true;
    };
    terminals = {
      alacritty = true;
      foot = true;
      kitty = true;
    };
    tui = {
      herdr = true;
      tmux = true;
    };
    utils = {
      fastfetch = true;
    };
  };
}
