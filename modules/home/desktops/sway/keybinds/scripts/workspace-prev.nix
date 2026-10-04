{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "sway-workspace-prev" ''
    ws=$(swaymsg -t get_workspaces -r | jq '[.[] | select(.representation != null) | .num] | sort | reverse')
    count=$(echo "$ws" | jq 'length')
    [ "$count" -le 1 ] && exit 0
    cur=$(swaymsg -t get_workspaces -r | jq '.[] | select(.focused) | .num')
    next=$(echo "$ws" | jq -r --argjson cur "$cur" '([.[] | select(. < $cur)] | first) // .[0]')
    swaymsg workspace number "$next"
  ''
