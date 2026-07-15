{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.development.lazygit;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.development.lazygit = mkOption {
    type = types.bool;
    default = false;
    description = "Enable lazygit (TUI for git).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [lazygit]);
}
