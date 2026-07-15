{
  config,
  lib,
  ...
}: let
  displayManager = config.hamra.displayManager;
in {
  options.hamra.displayManager = {
    default = lib.mkOption {
      type = lib.types.str;
      default = "sddm";
      description = "Display manager padrão.";
    };
    sddm = {
      theme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "silent";
        description = "Tema do SDDM.";
      };
      preset = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "catppuccin-mocha";
        description = "Preset do SDDM.";
      };
      profileIcon = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "profile.jpg";
        description = "Ícone de perfil do SDDM.";
      };
    };
  };

  config = {
    hamra.displayManager.sddm.profileIcon = lib.mkDefault (toString config.hamra.theme.profileIcon);

    services.displayManager.sddm = lib.mkIf (displayManager.default == "sddm") {
      enable = true;
      wayland.enable = true;
    };
  };
}
