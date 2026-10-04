{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.home.programs.terminals.kitty;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.terminals.kitty = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Kitty terminal configuration.";
  };

  config.programs.kitty = mkIf cfg {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
      tab_bar_style = "hidden";
    };
  };
}
