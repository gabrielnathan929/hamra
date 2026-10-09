#!/usr/bin/env bash
set -euo pipefail

REPO="${HAMRA_REPO:-$PWD}"
if [[ ! -f "$REPO/flake.nix" ]]; then
  echo "cookiecutter: flake.nix not found in $REPO" >&2
  echo "Run from the Hamra checkout or set HAMRA_REPO." >&2
  exit 1
fi

FROM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      FROM="${2:?--from needs a host name}"
      shift 2
      ;;
    --help | -h)
      echo "Usage: cookiecutter [--from <host>]"
      echo "Shape a new Hamra machine: answer a few prompts, pick apps in fzf,"
      echo "and hamra-init writes + validates the atomic host."
      exit 0
      ;;
    *)
      echo "cookiecutter: unknown argument $1 (see --help)" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$FROM" && ! -d "$REPO/hosts/$FROM" ]]; then
  echo "cookiecutter: hosts/$FROM does not exist." >&2
  exit 1
fi

need() {
  "$@" || {
    echo "cookiecutter: aborted." >&2
    exit 1
  }
}

json_escape() {
  local raw="$1"
  raw="${raw//\\/\\\\}"
  raw="${raw//\"/\\\"}"
  printf "%s" "$raw"
}

toggle_lines() {
  local tree="$1" dir category file app desc
  dir="$REPO/modules/nixos/programs/$tree"
  for category in "$dir"/*/; do
    category="$(basename "$category")"
    for file in "$dir/$category"/*.nix; do
      [[ "$(basename "$file")" == "default.nix" ]] && continue
      app="$(basename "$file" .nix)"
      desc="$(grep -m1 'description = "' "$file" | sed -e 's/.*description = "//' -e 's/";\s*$//')"
      printf "%s/%s %s\n" "$category" "$app" "${desc:+— $desc}"
    done
  done | sort
}

enabled_from() {
  local host="$1"
  nix eval --accept-flake-config --json \
    ".#nixosConfigurations.$host.config.hamra.programs.optionals" \
    --apply 'cats: builtins.concatLists (builtins.attrValues (builtins.mapAttrs (cat: apps: builtins.filter (x: x != null) (builtins.attrValues (builtins.mapAttrs (app: on: if on then "${cat}/${app}" else null) apps))) cats))' \
    2>/dev/null | jq -r '.[]' || true
}

gum style --border rounded --padding "0 1" --margin "1 0" \
  "CookieCutter — shape your machine."

HOSTNAME="$(need gum input --prompt "Machine name: " --placeholder "my-pc")"
while [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]] || [[ -e "$REPO/hosts/$HOSTNAME" ]]; do
  if [[ -e "$REPO/hosts/$HOSTNAME" ]]; then
    gum style --foreground 1 "hosts/$HOSTNAME already exists — pick another name."
  else
    gum style --foreground 1 "Use letters, numbers and hyphens."
  fi
  HOSTNAME="$(need gum input --prompt "Machine name: " --placeholder "my-pc")"
done

USERNAME="$(need gum input --prompt "Username: " --value "$USER")"
while [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; do
  gum style --foreground 1 "Use lowercase letters, numbers, hyphen or underscore."
  USERNAME="$(need gum input --prompt "Username: " --value "$USER")"
done

LOCALE="$(need gum input --prompt "Locale (empty = default): " --placeholder "pt_BR.UTF-8")"
TIMEZONE="$(need gum input --prompt "Timezone (empty = default): " --placeholder "America/Sao_Paulo")"
THEME="$(need gum input --prompt "Theme (empty = default): " --placeholder "dragon-ball")"
GPU="$(need gum choose --header "GPU" intel amd nvidia virtio)"
FIRMWARE="$(need gum choose --header "Firmware" uefi bios)"
DESKTOP="$(need gum choose --header "Desktop" hyprland sway niri gnome plasma)"
DISPLAY_MANAGER="$(need gum choose --header "Display manager" sddm greetd)"

KEYMAP=""
VARIANT=""
if gum confirm "Custom keyboard? (default br/abnt2)"; then
  KEYMAP="$(need gum input --prompt "keymap: " --value "us")"
  VARIANT="$(need gum input --prompt "xkbVariant (empty = none): " --placeholder "intl")"
fi

NAS="false"
if gum confirm "Is this machine the NAS (Samba)?"; then NAS="true"; fi
VNC="false"
if gum confirm "Run the wayvnc server here?"; then VNC="true"; fi
if [[ "$VNC" == "true" && "$DESKTOP" != "hyprland" && "$DESKTOP" != "sway" ]]; then
  gum style --foreground 3 "wayvnc needs hyprland or sway — turning it off."
  VNC="false"
fi

EDITOR_PKG="$(need gum input --prompt "Editor package (empty = default): " --placeholder "neovim")"
BROWSER_PKG="$(need gum input --prompt "Browser package (empty = default): " --placeholder "chromium")"
TERMINAL_PKG="$(need gum input --prompt "Terminal package (empty = default): " --placeholder "foot")"
FILES_PKG="$(need gum input --prompt "File manager package (empty = default): " --placeholder "thunar")"

FZF_PREVIEW_OPTIONALS="sed -n '1,25p' $REPO/modules/nixos/programs/optionals/{1}.nix"
INHERITED=()
if [[ -n "$FROM" ]]; then
  mapfile -t INHERITED < <(enabled_from "$FROM")
  gum style --foreground 2 "Inheriting ${#INHERITED[@]} optionals from $FROM — pick more below."
fi
mapfile -t ENABLED < <(toggle_lines optionals | fzf --multi --prompt "optionals> " \
  --header "TAB selects" \
  --preview "$FZF_PREVIEW_OPTIONALS" \
  --preview-window "right,50%" || true)

mapfile -t CORE_DISABLED < <(toggle_lines core | fzf --multi --prompt "core to disable> " \
  --header "TAB selects core apps to turn OFF (empty = keep all)" \
  --preview "sed -n '1,25p' $REPO/modules/nixos/programs/core/{1}.nix" \
  --preview-window "right,50%" || true)

to_json_array() {
  local item first=1
  printf "["
  for item in "$@"; do
    [[ -z "$item" ]] && continue
    if [[ $first -eq 1 ]]; then first=0; else printf ", "; fi
    printf '"%s"' "${item%% *}"
  done
  printf "]"
}

ANSWERS="$(mktemp)"
trap 'rm -f "$ANSWERS"' EXIT
{
  printf '{\n'
  printf '  "hostname": "%s",\n' "$(json_escape "$HOSTNAME")"
  printf '  "username": "%s",\n' "$(json_escape "$USERNAME")"
  [[ -n "$LOCALE" ]] && printf '  "locale": "%s",\n' "$(json_escape "$LOCALE")"
  [[ -n "$TIMEZONE" ]] && printf '  "timezone": "%s",\n' "$(json_escape "$TIMEZONE")"
  [[ -n "$THEME" ]] && printf '  "theme": "%s",\n' "$(json_escape "$THEME")"
  printf '  "gpu": "%s",\n' "$GPU"
  printf '  "firmware": "%s",\n' "$FIRMWARE"
  printf '  "desktop": "%s",\n' "$DESKTOP"
  printf '  "displayManager": "%s",\n' "$DISPLAY_MANAGER"
  if [[ -n "$KEYMAP" ]]; then
    if [[ -n "$VARIANT" ]]; then
      printf '  "keyboard": {"keymap": "%s", "xkbVariant": "%s"},\n' \
        "$(json_escape "$KEYMAP")" "$(json_escape "$VARIANT")"
    else
      printf '  "keyboard": {"keymap": "%s"},\n' "$(json_escape "$KEYMAP")"
    fi
  else
    printf '  "keyboard": null,\n'
  fi
  printf '  "nas": %s,\n' "$NAS"
  printf '  "vnc": %s,\n' "$VNC"
  if [[ -n "$EDITOR_PKG$BROWSER_PKG$TERMINAL_PKG$FILES_PKG" ]]; then
    printf '  "env": {'
    printf '"editor": "%s", ' "$(json_escape "${EDITOR_PKG:-neovim}")"
    printf '"browser": "%s", ' "$(json_escape "${BROWSER_PKG:-chromium}")"
    printf '"terminal": "%s", ' "$(json_escape "${TERMINAL_PKG:-foot}")"
    printf '"filemanager": "%s"},\n' "$(json_escape "${FILES_PKG:-thunar}")"
  fi
  printf '  "enable": %s,\n' "$(to_json_array "${INHERITED[@]}" "${ENABLED[@]}")"
  printf '  "core_disable": %s\n' "$(to_json_array "${CORE_DISABLED[@]}")"
  printf '}\n'
} > "$ANSWERS"

gum style --foreground 2 "Answers ready — handing over to hamra-init."
HAMRA_REPO="$REPO" python3 "$REPO/scripts/hamra-init.py" --answers "$ANSWERS"
