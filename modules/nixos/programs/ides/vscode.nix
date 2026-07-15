{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.ides.vscode;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.ides.vscode = mkOption {
    type = types.bool;
    default = false;
    description = "Enable VS Code (FHS).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [vscode-fhs]);
}
