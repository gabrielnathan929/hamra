{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "sway-workspace-next" ''
    ws=$(swaymsg -t get_workspaces -r | jq '[.[] | select(.representation != null) | .num] | sort')
    cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
    next=$(echo "$ws" | jq -r --argjson cur "$cur" '([.[] | select(. != $cur)] | [.[] | select(. > $cur)] | first) // ([.[] | select(. != $cur)] | first)')
    [[ -z $next || $next == null ]] && exit 0
    swaymsg workspace number "$next"
  ''
