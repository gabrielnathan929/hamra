{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.ides.pycharm;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.ides.pycharm = mkOption {
    type = types.bool;
    default = false;
    description = "Enable PyCharm Professional.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [jetbrains.pycharm]);
}
