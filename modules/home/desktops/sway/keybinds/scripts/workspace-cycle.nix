{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "sway-workspace-cycle" ''
    direction=''${1:-next}
    cur=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused) | .num')
    target=$(swaymsg -t get_workspaces -r | jq -r --argjson cur "$cur" --arg dir "$direction" '
      ([.[] | select(.representation != null and .num != null) | .num] - [$cur] | sort) as $cand
      | if $cand == [] then empty
        elif $dir == "prev" then (($cand | map(select(. < $cur)) | first) // ($cand | last))
        else (($cand | map(select(. > $cur)) | first) // ($cand | first))
        end')

    if [ -z "$target" ]; then
      exit 0
    fi

    swaymsg workspace number "$target"
  ''
