_: {
  hamra = {
    networking.hostname = "vm-nas";

    users = {
      email = "nas@hamra.local";
      fullName = "VM NAS";
      userName = "gabrielnathan";
    };

    locale = "en_US.UTF-8";

    timezone = "UTC";

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
