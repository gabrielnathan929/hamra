{
  config,
  lib,
  ...
}: let
  cfg = config.hamra.programs.optionals.services.appimage;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.services.appimage = mkOption {
    type = types.bool;
    default = false;
    description = "Enable AppImage support (appimage-run + binfmt).";
  };

  config.programs.appimage = mkIf cfg {
    enable = true;
    binfmt = true;
  };
}
