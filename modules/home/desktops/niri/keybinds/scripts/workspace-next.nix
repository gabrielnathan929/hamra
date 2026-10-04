{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "niri-workspace-next" ''
    counts=$(niri msg windows -j | jq -r 'group_by(.workspace_id) | map({key: (.[0].workspace_id | tostring), value: length}) | from_entries | to_entries[] | select(.value > 0) | .key' | sort -n)
    [[ -z $counts ]] && exit 0
    total=$(echo "$counts" | wc -l)
    [[ $total -le 1 ]] && exit 0
    cur=$(niri msg workspaces -j | jq -r '.[] | select(.is_focused) | .id')
    next=$(echo "$counts" | awk -v cur="$cur" '$1 > cur {print; exit}')
    next=''${next:-$(echo "$counts" | head -1)}
    [[ -z $next ]] && exit 0
    niri msg action focus-workspace "$next"
  ''
