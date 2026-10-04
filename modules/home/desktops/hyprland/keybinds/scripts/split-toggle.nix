{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "hypr-split-toggle" ''
    layout=$(hyprctl activeworkspace -j | jq -r '.tiledLayout')

    if [[ $layout == scrolling ]]; then
      out=$(hyprctl dispatch "hl.dsp.layout('consume_or_expel next')")
      if [[ $out != ok* ]]; then
        hyprctl dispatch "hl.dsp.layout('consume_or_expel prev')" >/dev/null
      fi
    else
      hyprctl dispatch "hl.dsp.layout('togglesplit')"
    fi
  ''
