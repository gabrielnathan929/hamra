{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.services.samba;
  inherit (lib) mkOption mkIf types stringAfter;
  userName = config.hamra.users.userName;
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
        shared = {
          path = "/data/shared";
          comment = "Documentos e arquivos gerais";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = userName;
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        games = {
          path = "/data/games";
          comment = "Instaladores, ROMs e jogos arquivados (storage frio)";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = userName;
          "create mask" = "0644";
          "directory mask" = "0755";
        };
        backups = {
          path = "/data/backups";
          comment = "Backups dos notebooks";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = userName;
          "create mask" = "0644";
          "directory mask" = "0755";
        };
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

    # Mantém a senha Samba sincronizada com o segredo a cada rebuild/boot.
    # Roda depois do setupSecrets do sops-nix (que popula /run/secrets).
    system.activationScripts.sync-samba-password = stringAfter ["setupSecrets"] ''
      ${pkgs.coreutils}/bin/mkdir -p /var/lib/samba/private
      ${pkgs.coreutils}/bin/printf '%s\n%s\n' \
        "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."samba-password".path})" \
        "$(${pkgs.coreutils}/bin/cat ${config.sops.secrets."samba-password".path})" \
        | ${pkgs.samba}/bin/smbpasswd -sa "${userName}"
    '';
  };
}
