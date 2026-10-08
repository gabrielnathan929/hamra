{
  config,
  lib,
  ...
}: let
  networking = config.hamra.networking;
in {
  options.hamra.networking.hostname = lib.mkOption {
    type = lib.types.str;
    default = "nixos";
    description = "Machine hostname.";
  };

  config.networking = {
    hostName = lib.mkDefault networking.hostname;
    networkmanager.enable = lib.mkDefault true;
    networkmanager.insertNameservers = ["1.1.1.1" "8.8.8.8"];
    firewall.enable = lib.mkDefault true;
  };
}
