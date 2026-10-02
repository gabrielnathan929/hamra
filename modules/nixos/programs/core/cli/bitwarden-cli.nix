{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli."bitwarden-cli";
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli."bitwarden-cli" = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Bitwarden CLI (bw).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.bitwarden-cli];
}
