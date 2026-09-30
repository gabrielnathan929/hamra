{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.unrar;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.unrar = mkOption {
    type = types.bool;
    default = true;
    description = "Enable unrar.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.unrar];
}
