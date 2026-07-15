{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.security.ente-auth;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.security."ente-auth" = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Ente Auth (2FA).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [ente-auth]);
}
