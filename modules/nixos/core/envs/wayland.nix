{
  config,
  lib,
  pkgs,
  ...
}: let
  isWayland = builtins.elem config.hamra.desktop.default [
    "hyprland"
    "niri"
    "sway"
  ];
in
  lib.mkIf isWayland {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";

      XDG_SESSION_TYPE = "wayland";
      GDK_BACKEND = "wayland,x11,*";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_STYLE_OVERRIDE = "kvantum";
      MOZ_ENABLE_WAYLAND = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      OZONE_PLATFORM = "wayland";

      HYPRCURSOR_SIZE = "24";

      XCOMPOSEFILE = "~/.XCompose";
    };

    environment.systemPackages = with pkgs; [
    ];
  }
