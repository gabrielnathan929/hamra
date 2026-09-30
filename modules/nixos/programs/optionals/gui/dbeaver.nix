{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.dbeaver;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.dbeaver = mkOption {
    type = types.bool;
    default = false;
    description = "Enable DBeaver (database manager).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [dbeaver-bin]);
}
