{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.yazi;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.yazi = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Yazi (terminal file manager).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.yazi];
}
