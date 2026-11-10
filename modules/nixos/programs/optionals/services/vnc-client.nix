{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.services.vnc-client;
  inherit (lib) mkOption mkIf types;

  userName = config.hamra.users.userName;
  secretsPath = config.hamra.secrets.path;

  vncHost = config.home-manager.users.${userName}.hamra.home.programs.shell.vncHost;
  passwordFile = config.sops.secrets."vnc-password".path;
  certFile = ./wayvnc-cert.pem;

  clientScript = pkgs.writeShellScript "vnc-client" ''
    set -eu

    password_file=${lib.escapeShellArg passwordFile}
    host=${lib.escapeShellArg vncHost}

    if [ ! -r "$password_file" ]; then
      echo "[vnc-client] $password_file is not readable (sops secret missing?)" >&2
      exit 1
    fi

    VNC_PASSWORD=$(tr -d '\n\r' <"$password_file")
    if [ -z "$VNC_PASSWORD" ]; then
      echo "[vnc-client] $password_file is empty" >&2
      exit 1
    fi
    export VNC_PASSWORD
    export VNC_USERNAME=${lib.escapeShellArg userName}

    if [ -z "''${DISPLAY:-}" ]; then
      for socket in /tmp/.X11-unix/X*; do
        [ -S "$socket" ] || continue
        name="''${socket##*/X}"
        case "$name" in
          *[!0-9]* | "") continue ;;
        esac
        DISPLAY=":$name"
        export DISPLAY
        break
      done
    fi

    echo "[vnc-client] connecting to $host (display ''${DISPLAY:-none}, user ${userName})" >&2
    exec ${pkgs.tigervnc}/bin/vncviewer \
      -SecurityTypes X509Plain \
      -X509CA ${certFile} \
      -RemoteResize=0 \
      -AlertOnFatalError=0 \
      -ReconnectOnError=0 \
      "$host"
  '';
in {
  options.hamra.programs.optionals.services.vnc-client = mkOption {
    type = types.bool;
    default = false;
    description = "Run the TigerVNC client as a user service that connects to hamra.home.programs.shell.vncHost at login and reconnects when the link drops.";
  };

  config = mkIf cfg (lib.mkMerge [
    {
      systemd.user.services.vnc-client = {
        description = "VNC client — automatic connection to ${vncHost}";
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 5;
          ExecStart = "${clientScript}";
        };
      };
    }

    {
      sops = {
        age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

        secrets."vnc-password" = {
          sopsFile = "${secretsPath}/vnc.yaml";
          owner = userName;
          mode = "0400";
        };
      };
    }

    {
      assertions = [
        {
          assertion = vncHost != null;
          message = "hamra.programs.optionals.services.vnc-client requires hamra.home.programs.shell.vncHost on this host (e.g. \"192.168.1.15:5900\").";
        }
      ];
    }
  ]);
}
