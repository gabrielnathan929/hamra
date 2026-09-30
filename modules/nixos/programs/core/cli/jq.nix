{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.jq;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.jq = mkOption {
    type = types.bool;
    default = true;
    description = "Enable jq JSON processor.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.jq];
}
