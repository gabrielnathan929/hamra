_: {
  hamra = {
    networking.hostname = "desktop-full";

    users = {
      email = "devgabrielnathan@gmail.com";
      fullName = "Gabriel Nathan dos Santos Pires";
      userName = "gabrielnathan";
    };

    locale = "pt_BR.UTF-8";

    timezone = "America/Sao_Paulo";

    theme.name = "dragon-ball";

    gc = {
      enable = true;
      keepDays = 30;
      maxGenerations = 20;
      schedule = "weekly";
    };

    printing = true;

    services = {
      gnupg = true;
      keyring = true;
      polkit = true;
      sshd = true;
    };

    firewall = {
      enable = true;
      ports = {
        dev = false;
        http = false;
        https = false;
        jellyfin = false;
        kdeconnect = false;
        mosh = false;
        mpd = false;
        printer = false;
        rdp = false;
        samba = false;
        ssh = true;
        syncthing = false;
        vnc = false;
      };
    };
  };
}
