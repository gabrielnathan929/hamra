_: {
  hamra = {
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
        wine = false;
      };
      gui = {
        "android-studio" = false;
        bitwarden = false;
        boxes = false;
        brmodelo = false;
        bruno = false;
        "camunda-modeler" = false;
        chromium = false;
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
        obsidian = false;
        office = false;
        postman = false;
        pycharm = false;
        remmina = false;
        upscayl = false;
        vesktop = false;
        "virt-manager" = false;
        vscode = true;
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
        docker = true;
        "docker-compose" = false;
        samba = true;
        tigervnc = false;
        wayvnc = false;
        "wayvnc-no-auth" = false;
      };
      tui = {
        cliamp = false;
        lazydocker = false;
        lazygit = true;
        yazi = true;
      };
    };
  };
}
