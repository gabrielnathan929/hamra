{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.yq;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.yq = mkOption {
    type = types.bool;
    default = true;
    description = "Enable yq.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.yq];
}
