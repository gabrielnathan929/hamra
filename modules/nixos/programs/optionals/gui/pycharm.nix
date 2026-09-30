{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.pycharm;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.pycharm = mkOption {
    type = types.bool;
    default = false;
    description = "Enable PyCharm Professional.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [jetbrains.pycharm]);
}
