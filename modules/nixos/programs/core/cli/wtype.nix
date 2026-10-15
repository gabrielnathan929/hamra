{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.wtype;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.wtype = mkOption {
    type = types.bool;
    default = true;
    description = "Enable wtype.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.wtype];
}
