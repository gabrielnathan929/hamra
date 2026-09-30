{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.lazygit;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.lazygit = mkOption {
    type = types.bool;
    default = false;
    description = "Enable lazygit (TUI for git).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [lazygit]);
}
