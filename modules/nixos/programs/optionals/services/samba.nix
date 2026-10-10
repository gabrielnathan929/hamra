{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.services.samba;
  inherit (lib) mkOption mkIf types stringAfter;
  userName = config.hamra.users.userName;
  recycleOpts = {
    "vfs objects" = "recycle";
    "recycle:repository" = ".trash";
    "recycle:versions" = "Yes";
    "recycle:keeptree" = "Yes";
    "recycle:touch" = "Yes";
    "recycle:maxsize" = "0";
    "recycle:exclude" = "*.tmp,*.TMP,~$*";
    "recycle:noversions" = "*.tmp,*.TMP,~$*";
  };
in {
  options.hamra.programs.optionals.services.samba = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Samba NAS file server (shares: shared, games, backups).";
  };

  config = mkIf cfg {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "Hamra NAS";
          "map to guest" = "never";
          "hosts allow" = "127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16";
        };
        shared =
          {
            path = "/data/shared";
            comment = "General documents and files";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "valid users" = userName;
            "create mask" = "0644";
            "directory mask" = "0755";
          }
          // recycleOpts;
        games =
          {
            path = "/data/games";
            comment = "Installers, ROMs and archived games (cold storage)";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "valid users" = userName;
            "create mask" = "0644";
            "directory mask" = "0755";
          }
          // recycleOpts;
        backups =
          {
            path = "/data/backups";
            comment = "Notebook backups";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "no";
            "valid users" = userName;
            "create mask" = "0644";
            "directory mask" = "0755";
          }
          // recycleOpts;
      };
    };

    systemd.tmpfiles.rules = [
      "d /data/shared 0755 ${userName} users - -"
      "d /data/games 0755 ${userName} users - -"
      "d /data/backups 0755 ${userName} users - -"
    ];

    sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

    sops.secrets."samba-password" = {
      sopsFile = ../../../../../secrets/samba.yaml;
      mode = "0400";
    };

    system.activationScripts.sync-samba-password = stringAfter ["setupSecrets"] ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/samba/private
      secret="${config.sops.secrets."samba-password".path}"
      if [ ! -f "$secret" ]; then
        echo "hamra/samba: samba-password secret missing at $secret" >&2
        echo "This host age key cannot decrypt secrets/samba.yaml." >&2
        echo "Run on the host: cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age" >&2
        echo "Register the key in .sops.yaml and run: nix develop --command sops updatekeys secrets/samba.yaml" >&2
        echo "Onboarding: ./scripts/setup-nas.sh --help (or SETUP.md section 3)" >&2
        exit 1
      fi
      ${pkgs.coreutils}/bin/printf '%s\n%s\n' \
        "$(${pkgs.coreutils}/bin/cat "$secret")" \
        "$(${pkgs.coreutils}/bin/cat "$secret")" \
        | ${pkgs.samba}/bin/smbpasswd -sa "${userName}"
    '';
  };
}
