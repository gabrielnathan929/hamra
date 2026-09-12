{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides.dbeaver;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides.dbeaver = mkOption {
    type = types.bool;
    default = false;
    description = "Enable DBeaver (database manager).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [dbeaver-bin]);
}
