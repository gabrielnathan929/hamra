{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.yazi;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.yazi = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Yazi (terminal file manager).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.yazi];
}
