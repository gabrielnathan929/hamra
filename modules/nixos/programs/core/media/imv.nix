{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.media.imv;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.core.media.imv = mkOption {
    type = types.bool;
    default = true;
    description = "Enable imv image viewer.";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.imv];

    home-manager.users.${userName}.xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "image/avif" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/x-ico" = "imv.desktop";
        "image/x-portable-anymap" = "imv.desktop";
        "image/x-portable-bitmap" = "imv.desktop";
        "image/x-portable-graymap" = "imv.desktop";
        "image/x-portable-pixmap" = "imv.desktop";
        "image/x-tga" = "imv.desktop";
        "image/x-xbitmap" = "imv.desktop";
        "image/x-xpixmap" = "imv.desktop";
      };
    };
  };
}
