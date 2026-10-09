#!/usr/bin/env bash
# hamra-setup — graphical wizard for hamra-init using zenity dialogs.
#
# One dependency: zenity (GTK dialogs from bash). Uses only core zenity
# features (entry, list, radiolist, checklist, question, progress, text-info)
# that are stable across all zenity versions since 3.0.
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

# ─── Step 1: Machine name ───────────────────────────────────────────────

hostname=$(zenity --entry \
  --title="$title" \
  --text="Machine name\n(becomes hostname and hosts/<name>)" \
  --entry-text="" \
  2>/dev/null) || exit 0

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

# ─── Step 2: GPU ─────────────────────────────────────────────────────────

gpu=$(zenity --list --radiolist \
  --title="$title" \
  --text="GPU" \
  --column="" --column="GPU" \
  --height=280 \
  TRUE "intel" FALSE "amd" FALSE "nvidia" FALSE "virtio" \
  2>/dev/null) || gpu="intel"

# ─── Step 3: Firmware ────────────────────────────────────────────────────

fw_default="uefi"
if [ ! -d /sys/firmware/efi ]; then
  fw_default="bios"
fi

firmware=$(zenity --list --radiolist \
  --title="$title" \
  --text="Firmware (detected: $fw_default)" \
  --column="" --column="Firmware" \
  --height=200 \
  TRUE "$fw_default" FALSE "bios" \
  2>/dev/null) || firmware="$fw_default"

# ─── Step 4: Desktop ──────────────────────────────────────────────────────

desktop=$(zenity --list --radiolist \
  --title="$title" \
  --text="Desktop environment" \
  --column="" --column="Desktop" \
  --height=320 \
  TRUE "hyprland" FALSE "sway" FALSE "niri" FALSE "gnome" FALSE "plasma" \
  2>/dev/null) || desktop="hyprland"

# ─── Step 5: Host roles ──────────────────────────────────────────────────

nas="false"
vnc="false"

roles=$(zenity --list --checklist \
  --title="$title" \
  --text="Host roles (leave both unchecked if unsure)" \
  --column="" --column="Role" --column="Description" \
  --height=220 \
  FALSE "nas" "NAS (Samba shares)" \
  FALSE "vnc" "WayVNC server" \
  --separator="," \
  --print-column=2 \
  2>/dev/null) || roles=""

if echo "$roles" | grep -q "nas"; then
  nas="true"
fi
if echo "$roles" | grep -q "vnc"; then
  vnc="true"
fi

# WayVNC cross-rule: needs hyprland or sway
if [[ "$vnc" == "true" && "$desktop" != "hyprland" && "$desktop" != "sway" ]]; then
  vnc="false"
  zenity --info --title="$title" \
    --text="WayVNC needs hyprland or sway — disabled." 2>/dev/null || true
fi

# ─── Step 6: Keyboard (optional) ──────────────────────────────────────────

keyboard_json="null"
if zenity --question --title="$title" \
  --text="Custom keyboard layout for this machine?
(No keeps the base default: br/abnt2)" \
  --ok-label="Yes" --cancel-label="No" 2>/dev/null; then
  kb_keymap=$(zenity --entry --title="$title" \
    --text="keymap (e.g. us, br)" \
    --entry-text="us" 2>/dev/null) || kb_keymap="us"
  kb_variant=$(zenity --entry --title="$title" \
    --text="xkbVariant (e.g. intl, abnt2 — empty for none)" \
    --entry-text="" 2>/dev/null) || kb_variant=""
  keyboard_json="{\"keymap\": \"$kb_keymap\", \"xkbVariant\": \"$kb_variant\"}"
fi

# ─── Step 7: Apps to disable ─────────────────────────────────────────────

apps_args=()
apps_file="$REPO/hosts/profiles/gabrielnathan/apps.nix"
if [[ -f "$apps_file" ]]; then
  while read -r app; do
    app=$(echo "$app" | tr -d '"')
    apps_args+=("FALSE" "$app")
  done < <(grep -oP '^\s+\K[a-zA-Z0-9"-]+(?= = true)' "$apps_file" | sort -u)
fi

if [[ ${#apps_args[@]} -eq 0 ]]; then
  disable_json="[]"
else
  # zenity --list --checklist prints CHECKED items
  # We show all apps as unchecked; the user CHECKS what to disable
  disabled=$(zenity --list --checklist \
    --title="$title" \
    --text="Apps to DISABLE on this machine
(leave all unchecked to keep everything from the profile)" \
    --column="" --column="App" \
    --height=500 --width=350 \
    --separator="," \
    --print-column=2 \
    "${apps_args[@]}" \
    2>/dev/null) || disabled=""

  if [[ -z "$disabled" ]]; then
    disable_json="[]"
  else
    disable_json="["
    first=true
    while read -r app; do
      "$first" || disable_json+=","
      disable_json+="\"$app\""
      first=false
    done < <(echo "$disabled" | tr ',' '\n')
    disable_json+="]"
  fi
fi

# ─── Step 8: Confirm and generate ────────────────────────────────────────

summary="hosts/$hostname
  GPU: $gpu
  Firmware: $firmware
  Desktop: $desktop
  NAS: $nas
  VNC: $vnc"

if ! zenity --question --title="$title" \
  --text="$summary

Generate now?" \
  --ok-label="Generate" --cancel-label="Cancel" 2>/dev/null; then
  exit 0
fi

cat > "$ANSWERS_FILE" <<EOF
{
  "hostname": "$hostname",
  "gpu": "$gpu",
  "firmware": "$firmware",
  "desktop": "$desktop",
  "profile": "gabrielnathan",
  "nas": $nas,
  "vnc": $vnc,
  "keyboard": $keyboard_json,
  "disable": $disable_json
}
EOF

# ─── Step 9: Run the engine ──────────────────────────────────────────────

python3 "$ENGINE" --answers "$ANSWERS_FILE" > "$TMP_OUT" 2>&1 &
ENGINE_PID=$!
ENGINE_EXIT=0

zenity --progress \
  --title="$title" \
  --text="Generating hosts/$hostname and running validation gates..." \
  --pulsate --auto-close \
  2>/dev/null &
ZENITY_PID=$!

wait "$ENGINE_PID" || ENGINE_EXIT=$?
kill "$ZENITY_PID" 2>/dev/null || true

if [[ $ENGINE_EXIT -ne 0 ]]; then
  error_dialog "The engine failed (exit $ENGINE_EXIT).

$(tail -20 "$TMP_OUT")"
  exit 1
fi

zenity --text-info --title="$title — Result" \
  --filename="$TMP_OUT" \
  --width=700 --height=500 2>/dev/null || true

# ─── Step 10: Offer the rebuild ───────────────────────────────────────────

if zenity --question --title="$title" \
  --text="Host generated and validated.

Run the rebuild test now? (sudo nixos-rebuild test)

This does NOT change the boot menu." \
  --ok-label="Run test" --cancel-label="Skip" 2>/dev/null; then

  TMP_SUDO=$(mktemp)
  sudo sh -c "mkdir -p /root/.config/nix; grep -q '^experimental-features' /root/.config/nix/nix.conf 2>/dev/null || echo 'experimental-features = nix-command flakes' >> /root/.config/nix/nix.conf" 2>/dev/null || true

  sudo sh -c "nixos-rebuild test --flake '$REPO#$hostname' > '$TMP_SUDO' 2>&1" &
  SUDO_PID=$!
  TEST_EXIT=0

  zenity --progress --title="$title" \
    --text="Running nixos-rebuild test..." \
    --pulsate --auto-close \
    2>/dev/null &
  ZENITY_PID2=$!

  wait "$SUDO_PID" || TEST_EXIT=$?
  kill "$ZENITY_PID2" 2>/dev/null || true

  if [[ $TEST_EXIT -ne 0 ]]; then
    error_dialog "Rebuild test failed (exit $TEST_EXIT).

$(tail -10 "$TMP_SUDO")"
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
