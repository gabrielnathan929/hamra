{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.media.zathura;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.core.media.zathura = mkOption {
    type = types.bool;
    default = true;
    description = "Enable zathura document viewer (PDF, EPUB, DjVu, comics).";
  };

  config = mkIf cfg {
    environment.systemPackages = [pkgs.zathura];

    home-manager.users.${userName}.xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
        "application/postscript" = "org.pwmt.zathura.desktop";
        "application/x-cb7" = "org.pwmt.zathura.desktop";
        "application/x-cbr" = "org.pwmt.zathura.desktop";
        "application/x-cbt" = "org.pwmt.zathura.desktop";
        "application/x-cbz" = "org.pwmt.zathura.desktop";
        "application/x-pdf" = "org.pwmt.zathura.desktop";
        "image/vnd.djvu" = "org.pwmt.zathura.desktop";
      };
    };
  };
}
