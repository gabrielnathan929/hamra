{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.ides.bruno;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.ides.bruno = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Bruno (Open-source IDE For exploring and testing APIs).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [bruno]);
}
