{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "sway-alt-tab" ''
    direction=''${1:-next}
    tree=$(swaymsg -t get_tree)

    focused=$(jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused? == true) | .id' <<< "$tree")
    fullscreen=$(jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused? == true) | .fullscreen_mode // 0' <<< "$tree")
    ws=$(swaymsg -t get_workspaces | jq -r '.[] | select(.focused) | .num')

    [[ -z $ws || $ws == null ]] && exit 0

    ids=$(jq -r --argjson ws "$ws" '
      recurse(.nodes[]?, .floating_nodes[]?) |
      select(.type? == "workspace" and .num? == $ws) |
      recurse(.nodes[]?, .floating_nodes[]?) |
      select(.type? == "con" and (.app_id? != null or .window_properties?.class? != null)) |
      .id' <<< "$tree")

    [[ -z $ids ]] && exit 0

    mapfile -t windows <<< "$ids"
    count=''${#windows[@]}
    [[ $count -le 1 ]] && exit 0

    index=-1
    for i in "''${!windows[@]}"; do
      [[ "''${windows[$i]}" == "$focused" ]] && index=$i
    done
    [[ $index -lt 0 ]] && exit 0

    if [[ $direction == prev ]]; then
      target=$(((index - 1 + count) % count))
    else
      target=$(((index + 1) % count))
    fi

    swaymsg "[con_id=''${windows[$target]}]" focus

    if [[ "$fullscreen" == "1" ]]; then
      new_fullscreen=$(swaymsg -t get_tree | jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused? == true) | .fullscreen_mode // 0')
      [[ "$new_fullscreen" != "1" ]] && swaymsg fullscreen enable
    fi
  ''
