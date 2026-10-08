# Personal app picks for this profile. Everything enabled here applies to
# every host that imports the profile; a host turns any of them off with a
# plain "= false" delta.
#
# Host roles (samba NAS, wayvnc, tigervnc) are deliberately absent: they say
# what a machine IS and are declared per host.
{lib, ...}: {
  hamra.programs.optionals = lib.mkDefault {
    cli = {
      gcc = true;
      ffmpeg = true;
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
      android-studio = true;
      bitwarden = true;
      boxes = true;
      brmodelo = true;
      bruno = true;
      camunda-modeler = true;
      chromium = true;
      dbeaver = true;
      discord = true;
      drawio = true;
      ente-auth = true;
      firefox = true;
      google-chrome = true;
      helium = true;
      insomnia = true;
      intellij = true;
      keepassxc = true;
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
      vesktop = true;
      virt-manager = true;
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
      gnome-software = true;
      nix-software-center = true;
    };

    services = {
      appimage = true;
      docker = true;
      "docker-compose" = true;
    };

    tui = {
      cliamp = true;
      lazydocker = true;
      lazygit = true;
      yazi = true;
    };
  };
}
