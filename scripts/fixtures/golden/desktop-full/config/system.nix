_: {
  hamra = {
    networking.hostname = "test-desktop";

    users = {
      email = "devgabrielnathan@gmail.com";
      fullName = "Gabriel Nathan dos Santos Pires";
      userName = "tester";
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
  };
}
