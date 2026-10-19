{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.optionals.services.sunshine;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.services.sunshine = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Sunshine, the self-hosted game stream host for Moonlight (opens its own ports).";
  };

  config = mkIf cfg {
    services.sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;
    };
  };
}
