{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "niri-workspace-cycle" ''
    direction=''${1:-next}
    cur=$(niri msg workspaces -j | jq -r '.[] | select(.is_focused) | .id')
    target=$(niri msg windows -j | jq -r --argjson cur "$cur" --arg dir "$direction" '
      ([.[] | .workspace_id] | unique - [$cur]) as $cand
      | if $cand == [] then empty
        elif $dir == "prev" then (($cand | map(select(. < $cur)) | first) // ($cand | last))
        else (($cand | map(select(. > $cur)) | first) // ($cand | first))
        end')

    if [ -z "$target" ]; then
      exit 0
    fi

    niri msg action focus-workspace "$target"
  ''
