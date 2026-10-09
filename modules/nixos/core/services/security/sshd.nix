{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.services.sshd;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.services.sshd = mkOption {
    type = types.bool;
    default = true;
    description = "Enable SSH daemon.";
  };

  config = mkIf cfg {
    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
        AllowUsers = [config.hamra.users.userName];
        MaxAuthTries = 3;
        MaxSessions = 3;
        LoginGraceTime = "30s";
        ClientAliveInterval = 300;
        ClientAliveCountMax = 2;
      };
    };

    services.fail2ban.enable = true;
  };
}
