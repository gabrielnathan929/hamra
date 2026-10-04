{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.file;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.file = mkOption {
    type = types.bool;
    default = true;
    description = "Enable file.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.file];
}
