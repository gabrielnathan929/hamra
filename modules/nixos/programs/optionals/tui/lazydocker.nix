{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.lazydocker;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.lazydocker = mkOption {
    type = types.bool;
    default = false;
    description = "Enable lazydocker (TUI for Docker).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [lazydocker]);
}
