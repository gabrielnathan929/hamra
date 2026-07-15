{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "niri-workspace-prev" ''
    ws=$(niri msg workspaces -j | jq '[.[] | select(.windows_count > 0) | .id] | sort | reverse')
    count=$(echo "$ws" | jq 'length')
    [ "$count" -le 1 ] && exit 0
    cur=$(niri msg workspaces -j | jq '.[] | select(.is_active) | .id')
    next=$(echo "$ws" | jq -r --argjson cur "$cur" '([.[] | select(. < $cur)] | first) // .[0]')
    niri msg action focus-workspace "$next"
  ''
