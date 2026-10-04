{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "hypr-layout-toggle" ''
    active=$(hyprctl activeworkspace -j)
    id=$(jq -r '.id' <<< "$active")
    current=$(jq -r '.tiledLayout' <<< "$active")

    case "$current" in
      dwindle) new="scrolling" ;;
      *) new="dwindle" ;;
    esac

    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/hamra/workspace-layouts"
    mkdir -p "$state_dir"
    printf '%s' "$new" > "$state_dir/$id"

    hyprctl eval "hl.workspace_rule({ workspace = \"$id\", layout = \"$new\" })" >/dev/null 2>&1 ||
      hyprctl keyword workspace "$id, layout:$new"
  ''
