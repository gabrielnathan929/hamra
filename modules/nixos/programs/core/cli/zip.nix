{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.zip;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.zip = mkOption {
    type = types.bool;
    default = true;
    description = "Enable zip.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.zip];
}
