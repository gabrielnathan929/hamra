{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.dev.jq;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.dev.jq = mkOption {
    type = types.bool;
    default = false;
    description = "Enable jq JSON processor.";
  };

  config.home.packages = mkIf cfg [pkgs.jq];
}
