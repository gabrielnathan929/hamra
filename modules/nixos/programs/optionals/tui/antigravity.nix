{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.antigravity;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.antigravity = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Antigravity CLI (Google coding agent).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [antigravity]);
}
