{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.optionals.services.tailscale;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.services.tailscale = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Tailscale, the WireGuard mesh VPN (opens UDP 41641).";
  };

  config = mkIf cfg {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
  };
}
