{
  config,
  lib,
  ...
}: {
  options.hamra.desktop.default = lib.mkOption {
    type = lib.types.str;
    default = "hyprland";
    description = "Escolha o desktop padrão. Opções: hyprland, niri, sway.";
  };

  options.hamra.displays = lib.mkOption {
    type = lib.types.submodule {
      options = {
        physical = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              mode = lib.mkOption {
                type = lib.types.str;
                default = "preferred";
              };
              position = lib.mkOption {
                type = lib.types.str;
                default = "0x0";
              };
              scale = lib.mkOption {
                type = lib.types.float;
                default = 1.0;
              };
            };
          });
          default = {};
        };
        virtual = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              mode = lib.mkOption {
                type = lib.types.str;
                default = "1920x1080@60";
              };
              position = lib.mkOption {
                type = lib.types.str;
                default = "0x0";
              };
              scale = lib.mkOption {
                type = lib.types.float;
                default = 1.0;
              };
            };
          });
          default = {};
        };
        headless = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              mode = lib.mkOption {
                type = lib.types.str;
                default = "1920x1080@60";
              };
              position = lib.mkOption {
                type = lib.types.str;
                default = "1920x0";
              };
              scale = lib.mkOption {
                type = lib.types.float;
                default = 1.0;
              };
            };
          });
          default = {
            HEADLESS-1 = {};
          };
        };
      };
    };
    default = {};
  };

  imports = [
    ./hyprland
    ./niri
    ./sway
  ];
}
