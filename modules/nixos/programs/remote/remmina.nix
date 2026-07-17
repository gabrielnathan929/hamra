{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.remote.remmina;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.remote.remmina = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Remmina remote desktop client.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.remmina];
}
