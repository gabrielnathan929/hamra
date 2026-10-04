{pkgs, ...}: let
  inherit (pkgs) writeShellScript;
in
  writeShellScript "hypr-alt-tab" ''
    direction=''${1:-next}
    active=$(hyprctl activewindow -j)

    had_active=0
    internal=0
    client=0

    if jq -e 'type == "object"' <<< "$active" >/dev/null 2>&1; then
      had_active=1
      internal=$(jq -r '.fullscreen // 0' <<< "$active")
      client=$(jq -r '.fullscreenClient // 0' <<< "$active")
    fi

    if [[ $direction == prev ]]; then
      hyprctl dispatch cyclenext prev
    else
      hyprctl dispatch cyclenext
    fi
    hyprctl dispatch bringactivewindowtotop

    if [[ $had_active == 1 ]]; then
      new=$(hyprctl activewindow -j)
      new_internal=$(jq -r '.fullscreen // 0' <<< "$new")
      new_client=$(jq -r '.fullscreenClient // 0' <<< "$new")
      if [[ "$internal" != "$new_internal" || "$client" != "$new_client" ]]; then
        hyprctl dispatch fullscreenstate "$internal" "$client"
      fi
    fi
  ''
