{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.unrar;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.unrar = mkOption {
    type = types.bool;
    default = true;
    description = "Enable unrar.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.unrar];
}
