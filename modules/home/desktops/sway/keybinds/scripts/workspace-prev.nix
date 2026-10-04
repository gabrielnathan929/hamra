{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "sway-workspace-prev" ''
    ws=$(swaymsg -t get_workspaces -r | jq '[.[] | select(.representation != null) | .num] | sort | reverse')
    cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
    prev=$(echo "$ws" | jq -r --argjson cur "$cur" '([.[] | select(. != $cur)] | [.[] | select(. < $cur)] | first) // ([.[] | select(. != $cur)] | first)')
    [[ -z $prev || $prev == null ]] && exit 0
    swaymsg workspace number "$prev"
  ''
