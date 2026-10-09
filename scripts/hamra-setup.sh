#!/usr/bin/env bash
# hamra-setup — graphical wizard for hamra-init using zenity dialogs.
#
# One dependency: zenity (GTK dialogs from bash). The engine does all the
# work — this script only collects answers and displays progress.
#
# Usage:
#   nix run .#hamra-setup
#
# Fallback: if zenity is not available, points to the CLI wizard (hamra-init).

set -euo pipefail

REPO="${HAMRA_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
ENGINE="$REPO/scripts/hamra-init.py"
ANSWERS_FILE=$(mktemp --suffix=.json)
TMP_OUT=$(mktemp)

cleanup() { rm -f "$ANSWERS_FILE" "$TMP_OUT"; }
trap cleanup EXIT

if ! command -v zenity >/dev/null 2>&1; then
  echo "hamra-setup: zenity not found." >&2
  echo "Run the CLI wizard instead: nix run .#hamra-init" >&2
  exit 1
fi

title="Hamra Setup"
error_dialog() {
  zenity --error --title="$title" --text="$1" 2>/dev/null || true
}

# ─── Page 1: Machine identity and roles ─────────────────────────────────

identity=$(zenity --forms --title="$title" \
  --text="New machine — identity and roles" \
  --add-entry="Machine name" \
  --add-combo="GPU" --combo-values="intel|amd|nvidia|virtio" \
  --add-combo="Firmware" --combo-values="uefi|bios" \
  --add-combo="Desktop" --combo-values="hyprland|sway|niri|gnome|plasma" \
  --add-check="NAS (Samba shares)" \
  --add-check="WayVNC server" \
  --separator="|") || exit 0

IFS='|' read -r hostname gpu firmware desktop nas vnc <<< "$identity"

if [[ ! "$hostname" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*$ ]]; then
  error_dialog "Invalid machine name: use letters, numbers and hyphens."
  exit 1
fi
if [[ "$hostname" == "common" || "$hostname" == "profiles" ]]; then
  error_dialog "'common' and 'profiles' are reserved names."
  exit 1
fi
if [[ -d "$REPO/hosts/$hostname" ]]; then
  error_dialog "hosts/$hostname already exists — the installer never overwrites."
  exit 1
fi

# WayVNC cross-rule: needs hyprland or sway
if [[ "$vnc" == "TRUE" && "$desktop" != "hyprland" && "$desktop" != "sway" ]]; then
  vnc="FALSE"
  zenity --info --title="$title" \
    --text="WayVNC needs hyprland or sway — disabled." 2>/dev/null || true
fi

# ─── Page 2: Keyboard (optional) ────────────────────────────────────────

keyboard_json="null"
if zenity --question --title="$title" \
  --text="Custom keyboard layout for this machine?\n(No keeps the base default: br/abnt2)" \
  --ok-label="Yes" --cancel-label="No" 2>/dev/null; then
  kb=$(zenity --forms --title="$title" \
    --text="Keyboard layout" \
    --add-entry="keymap (e.g. us, br)" \
    --add-entry="xkbVariant (e.g. intl, abnt2 — empty for none)" \
    --separator="|") || kb="us|"
  IFS='|' read -r kb_keymap kb_variant <<< "$kb"
  keyboard_json="{\"keymap\": \"${kb_keymap:-us}\", \"xkbVariant\": \"${kb_variant:-}\"}"
fi

# ─── Page 3: Apps to disable ────────────────────────────────────────────

apps_args=()
apps_file="$REPO/hosts/profiles/gabrielnathan/apps.nix"
if [[ -f "$apps_file" ]]; then
  while read -r app; do
    app=$(echo "$app" | tr -d '"')
    for category in cli games gui media packaging services tui; do
      if grep -q "\"*${app}\"* = true" "$REPO/hosts/profiles/gabrielnathan/apps.nix" 2>/dev/null; then
        apps_args+=("TRUE" "${category}.${app}" "$category")
        break
      fi
    done
  done < <(grep -oP '^\s+\K[a-zA-Z0-9"-]+(?= = true)' "$apps_file" | sort -u)
fi

if [[ ${#apps_args[@]} -eq 0 ]]; then
  disable_json="[]"
else
  kept=$(zenity --list \
    --title="$title" \
    --text="Apps from the profile — uncheck what this machine should NOT have.
Leave all checked to keep everything." \
    --checklist \
    --column="Keep" --column="App" --column="Category" \
    --separator="," \
    --print-column=2 \
    --height=500 --width=450 \
    "${apps_args[@]}" \
    2>/dev/null) || kept=""

  if [[ -z "$kept" ]]; then
    disable_json="[]"
  else
    disable_json="["
    first=true
    while read -r app; do
      "$first" || disable_json+=","
      disable_json+="\"$app\""
      first=false
    done < <(echo "$kept" | tr ',' '\n')
    disable_json+="]"
  fi
fi

# ─── Page 4: Generate answers and run the engine ────────────────────────

nas_bool="false"
[[ "$nas" == "TRUE" ]] && nas_bool="true"
vnc_bool="false"
[[ "$vnc" == "TRUE" ]] && vnc_bool="true"

cat > "$ANSWERS_FILE" <<EOF
{
  "hostname": "$hostname",
  "gpu": "$gpu",
  "firmware": "$firmware",
  "desktop": "$desktop",
  "profile": "gabrielnathan",
  "nas": $nas_bool,
  "vnc": $vnc_bool,
  "keyboard": $keyboard_json,
  "disable": $disable_json
}
EOF

# ─── Page 5: Run the engine and stream output ──────────────────────────

python3 "$ENGINE" --answers "$ANSWERS_FILE" > "$TMP_OUT" 2>&1 &
ENGINE_PID=$!
ENGINE_EXIT=0

zenity --progress \
  --title="$title" \
  --text="Generating hosts/$hostname and running validation gates…" \
  --pulsate --auto-close \
  2>/dev/null &
ZENITY_PID=$!

wait "$ENGINE_PID" || ENGINE_EXIT=$?
kill "$ZENITY_PID" 2>/dev/null || true

if [[ $ENGINE_EXIT -ne 0 ]]; then
  zenity --error --title="$title" \
    --text="The engine failed (exit $ENGINE_EXIT).

$(tail -20 "$TMP_OUT")" \
    --width=600 2>/dev/null || true
  exit 1
fi

# Show the engine output
zenity --text-info --title="$title — Result" \
  --filename="$TMP_OUT" \
  --width=700 --height=500 2>/dev/null || true

# ─── Page 6: Offer the rebuild ─────────────────────────────────────────

if zenity --question --title="$title" \
  --text="Host generated and validated.

Run the rebuild test now? (sudo nixos-rebuild test)

This does NOT change the boot menu." \
  --ok-label="Run test" --cancel-label="Skip" 2>/dev/null; then

  sudo sh -c "mkdir -p /root/.config/nix; grep -q '^experimental-features' /root/.config/nix/nix.conf 2>/dev/null || echo 'experimental-features = nix-command flakes' >> /root/.config/nix/nix.conf" 2>/dev/null || true

  TMP_SUDO=$(mktemp)
  sudo sh -c "nixos-rebuild test --flake '$REPO#$hostname' > '$TMP_SUDO' 2>&1" &
  SUDO_PID=$!
  TEST_EXIT=0

  zenity --progress --title="$title" \
    --text="Running nixos-rebuild test…" \
    --pulsate --auto-close \
    2>/dev/null &
  ZENITY_PID2=$!

  wait "$SUDO_PID" || TEST_EXIT=$?
  kill "$ZENITY_PID2" 2>/dev/null || true

  if [[ $TEST_EXIT -ne 0 ]]; then
    zenity --error --title="$title" \
      --text="Rebuild test failed (exit $TEST_EXIT).

$(tail -10 "$TMP_SUDO")" \
      2>/dev/null || true
    rm -f "$TMP_SUDO"
    exit 1
  fi

  zenity --info --title="$title" \
    --text="Test activation passed.

To make it the boot default:
sudo nixos-rebuild switch --flake .#$hostname" \
    2>/dev/null || true
  rm -f "$TMP_SUDO"
else
  zenity --info --title="$title" \
    --text="Host ready.

Validate and apply manually:
sudo nixos-rebuild test --flake .#$hostname" \
    2>/dev/null || true
fi

zenity --info --title="$title" \
  --text="Done! Commit when you are happy:
git add hosts/$hostname
git commit -m 'feat(hosts): add $hostname (hamra-init)'" \
  2>/dev/null || true
