{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.bruno;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.bruno = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Bruno (Open-source IDE For exploring and testing APIs).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [bruno]);
}
