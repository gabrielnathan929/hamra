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
    assertions = [
      {
        assertion = config.programs.thunar.enable;
        message = "hamra.programs.core.gui.thunar requires programs.thunar.enable (archive plugin only loads through the wrapped module).";
      }

      {
        assertion = config.programs.thunar.plugins != [];
        message = "hamra.programs.core.gui.thunar requires programs.thunar.plugins (e.g. thunar-archive-plugin) for compress/extract actions.";
      }

      {
        assertion = config.services.tumbler.enable;
        message = "hamra.programs.core.gui.thunar requires services.tumbler.enable (D-Bus thumbnailer).";
      }

      {
        assertion = config.xdg.terminal-exec.enable && builtins.elem "foot.desktop" config.xdg.terminal-exec.settings.default;
        message = "hamra.programs.core.gui.thunar requires xdg.terminal-exec with foot.desktop (launches Terminal=true apps like nvim).";
      }
    ];

    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin
      ];
    };

    services.tumbler.enable = true;

    environment.systemPackages = with pkgs; [
      file-roller
    ];

    xdg.terminal-exec = {
      enable = true;
      settings.default = ["foot.desktop"];
    };

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
        "inode/directory" = "thunar.desktop";
      };

      xdg.configFile."Thunar/uca.xml" = {
        force = true;
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <actions>
          <action>
          	<icon>utilities-terminal</icon>
          	<name>Open Terminal Here</name>
          	<submenu></submenu>
          	<unique-id>1791319264423150-1</unique-id>
          	<command>foot --working-directory=%f</command>
          	<description>Open foot terminal in this directory</description>
          	<range></range>
          	<patterns>*</patterns>
          	<startup-notify/>
          	<directories/>
          </action>
          </actions>
        '';
      };
    };
  };
}
