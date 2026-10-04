{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminals.alacritty;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminals.alacritty = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Alacritty terminal configuration.";
  };

  config.programs.alacritty = mkIf cfg {
    enable = true;

    settings = {
      window = {
        padding = {
          x = 4;
          y = 4;
        };
        dynamic_padding = true;
      };

      font = {
        normal.family = "monospace";
        size = 10;
      };

      cursor.style = "Beam";
    };
  };
}
