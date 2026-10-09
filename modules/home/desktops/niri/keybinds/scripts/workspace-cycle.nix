{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "niri-workspace-cycle" ''
    direction=''${1:-next}
    ws_json=$(niri msg workspaces -j)
    win_json=$(niri msg windows -j)
    cur=$(echo "$ws_json" | jq -r '.[] | select(.is_focused) | .id')
    fou=$(echo "$ws_json" | jq -r '.[] | select(.is_focused) | .output')
    wids=$(echo "$win_json" | jq -c '[.[].workspace_id] | unique')
    target=$(echo "$ws_json" | jq -r --argjson cur "$cur" --arg fou "$fou" --argjson wids "$wids" --arg dir "$direction" '
      ([.[] | select(.output == $fou and (.id as $id | $wids | index($id))) | .id] - [$cur] | sort) as $cand
      | if $cand == [] then empty
        elif $dir == "prev" then (($cand | map(select(. < $cur)) | first) // ($cand | last))
        else (($cand | map(select(. > $cur)) | first) // ($cand | first))
        end')

    if [ -z "$target" ]; then
      exit 0
    fi

    niri msg action focus-workspace "$target"
  ''
