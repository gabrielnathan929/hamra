{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "sway-workspace-cycle" ''
    direction=''${1:-next}
    ws_json=$(swaymsg -t get_workspaces -r)
    cur=$(echo "$ws_json" | jq -r '.[] | select(.focused) | .num')
    fou=$(echo "$ws_json" | jq -r '.[] | select(.focused) | .output')
    target=$(echo "$ws_json" | jq -r --argjson cur "$cur" --arg fou "$fou" --arg dir "$direction" '
      ([.[] | select(.representation != null and .num != null and .output == $fou) | .num] - [$cur] | sort) as $cand
      | if $cand == [] then empty
        elif $dir == "prev" then (($cand | map(select(. < $cur)) | first) // ($cand | last))
        else (($cand | map(select(. > $cur)) | first) // ($cand | first))
        end')

    if [ -z "$target" ]; then
      exit 0
    fi

    swaymsg workspace number "$target"
  ''
