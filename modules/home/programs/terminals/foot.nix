{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.terminals.foot;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminals.foot = mkOption {
    type = types.bool;
    default = true;
    description = "Enable Foot terminal configuration.";
  };

  config = mkIf cfg {
    programs.foot = {
      enable = true;

      settings = {
        main = {
          font = "monospace:size=10";
          dpi-aware = "yes";
        };

        mouse = {
          hide-when-typing = true;
        };

        scrollback = {
          lines = 10000;
        };

        cursor = {
          style = "beam";
          blink = true;
        };
      };
    };

    xdg.configFile."foot/foot.ini".force = true;
  };
}
