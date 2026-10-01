{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.duf;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.duf = mkOption {
    type = types.bool;
    default = true;
    description = "Enable duf.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.duf];
}
