_: ''
  ws=$(hyprctl -j workspaces | jq '[.[] | select(.windows > 0 and .id > 0) | .id] | sort | reverse')
  count=$(echo "$ws" | jq 'length')
  [ "$count" -le 1 ] && exit 0
  cur=$(hyprctl activeworkspace -j | jq '.id')
  next=$(echo "$ws" | jq -r --argjson cur "$cur" '([.[] | select(. < $cur)] | first) // .[0]')
  hyprctl dispatch hl.dsp.focus '{workspace='"$next"'}'
''
