{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.appimagepool;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.appimagepool = mkOption {
    type = types.bool;
    default = false;
    description = "Enable AppImage Pool app store (Flathub) with AppImage binfmt support for downloaded AppImages.";
  };

  config = mkIf cfg {
    hamra.flatpak.apps = ["io.github.prateekmedia.appimagepool"];

    programs.appimage = {
      enable = true;
      binfmt = true;
    };
  };
}
