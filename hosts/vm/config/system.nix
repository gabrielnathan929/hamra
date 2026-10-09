_: {
  hamra = {
    networking.hostname = "vm";

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

    printing = false;

    services = {
      gnupg = true;
      keyring = true;
      polkit = true;
      sshd = true;
    };
  };
}
