{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "hypr-fullscreen" ''
    mode=''${1:-fullscreen}
    ws=$(hyprctl activeworkspace -j | jq -r '.name')

    if [[ $ws == special:* ]]; then
      hyprctl dispatch togglespecialworkspace scratchpad
    fi

    if [[ $mode == maximized ]]; then
      hyprctl dispatch fullscreen 1
    else
      hyprctl dispatch fullscreen 0
    fi
  ''
