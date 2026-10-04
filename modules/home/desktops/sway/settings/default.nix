{keyboard, ...}: let
  inputPart = import ./input.nix {inherit keyboard;};
  displayPart = import ./display.nix {};
in ''
  set $mod Mod4

  default_border none

  gaps inner 8
  gaps outer 4
  smart_gaps off

  corner_radius 20

  shadows enable
  shadow_blur_radius 4
  shadow_color #1a1a1aee

  blur enable
  blur_radius 3
  blur_passes 1

  # Cursor
  seat "*" {
    xcursor_theme Bibata-Modern-Classic 24
  }

  ${inputPart}

  ${displayPart}
''
