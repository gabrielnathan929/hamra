{pkgs, ...}: let
  leaveSpecial = import ../scripts/leave-special.nix {inherit pkgs;};
in ''
  ${leaveSpecial}
  ws=$(hyprctl -j workspaces | jq '[.[] | select(.windows > 0 and .id > 0) | .id] | sort | reverse')
  cur=$(hyprctl activeworkspace -j | jq '.id')
  prev=$(echo "$ws" | jq -r --argjson cur "$cur" '([.[] | select(. != $cur)] | [.[] | select(. < $cur)] | first) // ([.[] | select(. != $cur)] | first)')
  if [ -z "$prev" ] || [ "$prev" = "null" ]; then
    exit 0
  fi
  hyprctl dispatch "hl.dsp.focus({workspace=$prev})"
''
