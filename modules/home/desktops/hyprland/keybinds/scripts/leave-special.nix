{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "hypr-leave-special" ''
    special=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .activeSpecialWorkspace // ""')

    if [[ -n $special ]]; then
      hyprctl dispatch "hl.dsp.workspace.toggle_special('scratchpad')"
    fi
  ''
