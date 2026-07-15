{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.apps.gtk;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.apps.gtk = mkOption {
    type = types.bool;
    default = false;
    description = "Configure GTK icon theme and settings for folder icons.";
  };

  config = mkIf cfg {
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
      };
      font.name = "Sans";
      font.size = 10;
    };
  };
}
