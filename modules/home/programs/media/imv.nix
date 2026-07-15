{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.media.imv;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.media.imv = mkOption {
    type = types.bool;
    default = false;
    description = "Enable imv image viewer.";
  };

  config = mkIf cfg {
    home.packages = [pkgs.imv];
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "image/png" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/webp" = "imv.desktop";
      };
    };
    xdg.configFile."mimeapps.list".force = true;
  };
}
