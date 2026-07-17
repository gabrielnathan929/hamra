{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.terminal-tools.gum;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.terminal-tools.gum = mkOption {
    type = types.bool;
    default = true;
    description = "Enable gum TUI toolkit.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gum];
}
