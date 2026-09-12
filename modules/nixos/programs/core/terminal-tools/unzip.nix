{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.unzip;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.unzip = mkOption {
    type = types.bool;
    default = true;
    description = "Enable unzip.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.unzip];
}
