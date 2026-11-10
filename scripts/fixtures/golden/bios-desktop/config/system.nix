_: {
  hamra = {
    networking.hostname = "bios-desktop";

    users = {
      email = "bios@example.com";
      fullName = "Bios Test";
      userName = "gabrielnathan";
    };

    locale = "en_US.UTF-8";

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
        ssh = true;
        syncthing = false;
      };
    };
  };
}
