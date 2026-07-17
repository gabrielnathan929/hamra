{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.utils.fastfetch;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.utils.fastfetch = mkOption {
    type = types.bool;
    default = true;
    description = "Enable fastfetch system info.";
  };

  config.programs.fastfetch = mkIf cfg {
    enable = true;

    settings = {
      logo = {
        type = "small";
        padding = {
          right = 2;
        };
      };

      display = {
        separator = " → ";
      };

      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "wm"
        "de"
        "terminal"
        "cpu"
        "gpu"
        "memory"
        "disk"
        "battery"
        "localip"
        "separator"
        "colors"
      ];
    };
  };
}
