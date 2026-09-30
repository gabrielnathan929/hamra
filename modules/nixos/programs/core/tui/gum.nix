{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.tui.gum;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.tui.gum = mkOption {
    type = types.bool;
    default = true;
    description = "Enable gum TUI toolkit.";
  };

  config.environment.systemPackages = mkIf cfg [pkgs.gum];
}
