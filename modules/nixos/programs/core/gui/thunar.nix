{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.core.gui.thunar;
  inherit (lib) mkOption mkIf types;
  userName = config.hamra.users.userName;
in {
  options.hamra.programs.core.gui.thunar = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Thunar.";
  };

  config = mkIf cfg {
    environment.systemPackages = with pkgs; [
      thunar
      tumbler
      thunar-archive-plugin
      file-roller
    ];

    home-manager.users.${userName} = {
      xdg.mimeApps.defaultApplications = {
        "application/zip" = "org.gnome.FileRoller.desktop";
        "application/vnd.rar" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-bzip2" = "org.gnome.FileRoller.desktop";
        "application/x-gzip" = "org.gnome.FileRoller.desktop";
        "application/x-rar-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-tar" = "org.gnome.FileRoller.desktop";
        "application/x-xz" = "org.gnome.FileRoller.desktop";
      };

      xdg.configFile."xfce4/helpers.rc".text = ''
        [Default Applications]
        TerminalEmulator=foot
        TerminalEmulatorDismissed=true
      '';
    };
  };
}
