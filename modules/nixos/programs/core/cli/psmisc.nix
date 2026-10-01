{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.cli.psmisc;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.cli.psmisc = mkOption {
    type = types.bool;
    default = true;
    description = "Enable psmisc (killall, pstree).";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.psmisc];
}
