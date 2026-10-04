{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.rsync;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.rsync = mkOption {
    type = types.bool;
    default = true;
    description = "Enable rsync.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.rsync];
}
