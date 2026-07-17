{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.security.bitwarden;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.security.bitwarden = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Bitwarden Desktop (password manager).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [bitwarden-desktop]);
}
