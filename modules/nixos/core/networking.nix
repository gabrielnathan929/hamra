{
  config,
  lib,
  ...
}: let
  networking = config.hamra.networking;

  nameservers = [
    "94.140.14.14"
    "94.140.15.15"
    "1.1.1.1"
    "8.8.8.8"
  ];
in {
  options.hamra.networking.hostname = lib.mkOption {
    type = lib.types.str;
    default = "nixos";
    description = "Machine hostname.";
  };

  config.networking = {
    hostName = lib.mkDefault networking.hostname;
    firewall.enable = lib.mkDefault true;

    networkmanager = {
      enable = lib.mkDefault true;
      settings = {
        global-dns = {
          options = "edns0";
        };
        "global-dns-domain-*".servers = lib.concatStringsSep "," nameservers;
      };
    };
  };
}
