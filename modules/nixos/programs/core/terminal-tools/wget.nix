{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.wget;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.wget = mkOption {
    type = types.bool;
    default = true;
    description = "Enable wget.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.wget];
}
