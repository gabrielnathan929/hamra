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
      description = "Default display manager.";
    };
    sddm = {
      theme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "silent";
        description = "SDDM theme.";
      };
      preset = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "catppuccin-mocha";
        description = "SDDM preset.";
      };
      profileIcon = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "profile.jpg";
        description = "SDDM profile icon.";
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
