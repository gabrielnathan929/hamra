{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.utils.fastfetch;
  inherit (lib) mkOption mkIf types;

  swordfish = builtins.readFile ./Swordfish.txt;
  esc = builtins.substring 0 1 swordfish;

  color = c: str: builtins.readFile (pkgs.writeText "color-${c}" "${esc}[${c}m${str}");
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
        type = "file";
        source = "${./Swordfish.txt}";
        color = {"1" = "green";};
        padding = {
          top = 2;
          right = 6;
          left = 2;
        };
      };

      modules = [
        "break"
        {
          type = "custom";
          format = color "37" "┌─────────────────────────Hardware─────────────────────────┐";
        }
        {
          type = "host";
          key = " PC";
          keyColor = "green";
        }
        {
          type = "cpu";
          key = "│ ├";
          showPeCoreCount = true;
          keyColor = "green";
        }
        {
          type = "gpu";
          key = "│ ├";
          detectionMethod = "pci";
          keyColor = "green";
        }
        {
          type = "display";
          key = "│ ├󱄄";
          keyColor = "green";
        }
        {
          type = "disk";
          key = "│ ├󰋊";
          keyColor = "green";
        }
        {
          type = "memory";
          key = "│ ├";
          keyColor = "green";
        }
        {
          type = "swap";
          key = "└ └󰓡";
          keyColor = "green";
        }
        {
          type = "custom";
          format = color "37" "└──────────────────────────────────────────────────────────┘";
        }
        "break"
        {
          type = "custom";
          format = color "37" "┌─────────────────────────Software─────────────────────────┐";
        }
        {
          type = "command";
          key = " OS";
          keyColor = "blue";
          text = "nixos-version";
        }
        {
          type = "command";
          key = "│ ├󰘬";
          keyColor = "blue";
          text = ''
            nixos-version | cut -d. -f1-2
          '';
        }
        {
          type = "command";
          key = "│ ├󰘬";
          keyColor = "blue";
          text = ''
            echo nixos-$(nixos-version | cut -d. -f1-2)
          '';
        }
        {
          type = "kernel";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "wm";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "de";
          key = " DE";
          keyColor = "blue";
        }
        {
          type = "terminal";
          key = "│ ├";
          keyColor = "blue";
        }
        {
          type = "packages";
          key = "│ ├󰏖";
          keyColor = "blue";
        }
        {
          type = "wmtheme";
          key = "│ ├󰉼";
          keyColor = "blue";
        }
        {
          type = "command";
          key = "│ ├󰸌";
          keyColor = "blue";
          text = ''
            echo -e "\e[38m●\e[37m●\e[36m●\e[35m●\e[34m●\e[33m●\e[32m●\e[31m●"
          '';
        }
        {
          type = "terminalfont";
          key = "└ └";
          keyColor = "blue";
        }
        {
          type = "custom";
          format = color "37" "└──────────────────────────────────────────────────────────┘";
        }
        "break"
        {
          type = "custom";
          format = color "37" "┌───────────────────Age / Uptime / Update──────────────────┐";
        }
        {
          type = "command";
          key = "󱦟 OS Age";
          keyColor = "magenta";
          text = ''
            echo $(( ($(date +%s) - $(stat -c %W /)) / 86400 )) days
          '';
        }
        {
          type = "uptime";
          key = "󱫐 Uptime";
          keyColor = "magenta";
        }
        {
          type = "command";
          key = " Update";
          keyColor = "magenta";
          text = ''
            echo "$(nix-store --query --requisites /run/current-system | wc -l) pkgs"
          '';
        }
        {
          type = "custom";
          format = color "37" "└──────────────────────────────────────────────────────────┘";
        }
        "break"
      ];
    };
  };
}
