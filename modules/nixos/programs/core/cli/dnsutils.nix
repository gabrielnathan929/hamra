{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.dnsutils;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.dnsutils = mkOption {
    type = types.bool;
    default = true;
    description = "Enable dnsutils (dig, nslookup).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.dnsutils];
}
