{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides.pycharm;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides.pycharm = mkOption {
    type = types.bool;
    default = false;
    description = "Enable PyCharm Professional.";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [jetbrains.pycharm]);
}
