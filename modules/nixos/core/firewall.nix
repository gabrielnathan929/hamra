{
  config,
  lib,
  ...
}: let
  inherit (lib) mkForce mkIf mkMerge mkOption types concatMap filter intersectLists unique;
  cfg = config.hamra.firewall;

  portSets = {
    ssh.tcp = [22];
    mosh.udpRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ];
    http.tcp = [80];
    https.tcp = [443];
    dev.tcp = [3000 3001 4000 4200 5000 5001 5173 5174 8000 8001 8080 8081 8082 9000 19000 19001 19002];
    vnc.tcp = [5900];
    rdp.tcp = [3389];
    samba = {
      tcp = [139 445];
      udp = [137 138];
    };
    syncthing = {
      tcp = [8384 22000];
      udp = [21027];
    };
    kdeconnect = {
      tcpRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      udpRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
    jellyfin = {
      tcp = [8096 8920];
      udp = [1900 7359];
    };
    printer = {
      tcp = [631];
      udp = [5353];
    };
    mpd.tcp = [6600];
  };

  knownNames = builtins.attrNames portSets;
  userNames = builtins.attrNames cfg.ports;
  unknownNames = filter (name: !builtins.elem name knownNames) userNames;
  activeNames = filter (name: cfg.ports.${name}) (intersectLists knownNames userNames);
  collect = field: unique (concatMap (name: portSets.${name}.${field} or []) activeNames);
in {
  options.hamra.firewall = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the firewall. Setting false opens every port.";
    };

    ports = mkOption {
      type = types.attrsOf types.bool;
      default = {
        ssh = true;
        mosh = false;
        http = false;
        https = false;
        dev = false;
        vnc = false;
        rdp = false;
        samba = false;
        syncthing = false;
        kdeconnect = false;
        jellyfin = false;
        printer = false;
        mpd = false;
      };
      description = "Common service ports to open, by name. The wayvnc and samba toggles open their own ports when enabled.";
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = unknownNames == [];
          message =
            "hamra.firewall.ports has unknown names: ${builtins.toString unknownNames}. "
            + "Valid: ${builtins.toString knownNames}";
        }
      ];
    }
    (mkIf (!cfg.enable) {
      networking.firewall.enable = mkForce false;
    })
    (mkIf cfg.enable {
      networking.firewall = {
        allowedTCPPorts = collect "tcp";
        allowedUDPPorts = collect "udp";
        allowedTCPPortRanges = collect "tcpRanges";
        allowedUDPPortRanges = collect "udpRanges";
      };
    })
  ];
}
