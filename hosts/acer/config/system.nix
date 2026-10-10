_: {
  hamra = {
    networking.hostname = "acer";

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
        ssh = true;
        mosh = false;
        http = false;
        https = false;
        dev = true;
        vnc = false;
        rdp = false;
        samba = true;
        syncthing = false;
        kdeconnect = false;
        jellyfin = false;
        printer = false;
        mpd = false;
      };
    };
  };
}
