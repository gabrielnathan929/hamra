{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.localsend;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.localsend = mkOption {
    type = types.bool;
    default = false;
    description = "Enable LocalSend file sharing (opens TCP/UDP 53317).";
  };

  config = mkIf cfg {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "localsend" ''
        exec ${pkgs.localsend}/bin/localsend_app "$@"
      '')
      pkgs.localsend
    ];

    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    networking.firewall = {
      allowedTCPPorts = [53317];
      allowedUDPPorts = [53317 5353];
    };
  };
}
