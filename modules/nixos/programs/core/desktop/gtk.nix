{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.desktop.gtk;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.core.desktop.gtk = mkOption {
    type = types.bool;
    default = true;
    description = "Configure GTK icon theme and settings for folder icons.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [
      papirus-icon-theme
      bibata-cursors
    ];

    environment.sessionVariables = {
      GTK_ICON_THEME = "Papirus";
      GTK_CURSOR_THEME = "Bibata-Modern-Classic";
    };
  };
}
