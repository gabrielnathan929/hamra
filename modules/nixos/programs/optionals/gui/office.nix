{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.gui.office;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.optionals.gui.office = mkOption {
    type = types.bool;
    default = false;
    description = "Enable LibreOffice.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [
      libreoffice-fresh
    ];

    home-manager.users.${userName}.xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/msword" = "writer.desktop";
        "application/rtf" = "writer.desktop";
        "application/vnd.oasis.opendocument.database" = "base.desktop";
        "application/vnd.oasis.opendocument.formula" = "math.desktop";
        "application/vnd.oasis.opendocument.graphics" = "draw.desktop";
        "application/vnd.oasis.opendocument.graphics-template" = "draw.desktop";
        "application/vnd.oasis.opendocument.presentation" = "impress.desktop";
        "application/vnd.oasis.opendocument.presentation-template" = "impress.desktop";
        "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop";
        "application/vnd.oasis.opendocument.spreadsheet-template" = "calc.desktop";
        "application/vnd.oasis.opendocument.text" = "writer.desktop";
        "application/vnd.oasis.opendocument.text-template" = "writer.desktop";
        "application/vnd.ms-excel" = "calc.desktop";
        "application/vnd.ms-powerpoint" = "impress.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = "impress.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.template" = "impress.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = "calc.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = "writer.desktop";
        "application/vnd.visio" = "draw.desktop";
      };
    };
  };
}
