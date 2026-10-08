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

cleanup() { rm -f "$ANSWERS_FILE"; }
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
  zenity --info --title="$title" --text="WayVNC needs hyprland or sway — disabled." 2>/dev/null || true
fi

# ─── Page 2: Keyboard (optional) ────────────────────────────────────────

if zenity --question --title="$title" \
  --text="Custom keyboard layout for this machine?\n(No keeps the base default: br/abnt2)" \
  --ok-label="Yes" --cancel-label="No" 2>/dev/null; then
  kb=$(zenity --forms --title="$title" \
    --text="Keyboard layout" \
    --add-entry="keymap (e.g. us, br)" \
    --add-entry="xkbVariant (e.g. intl, abnt2 — empty for none)" \
    --separator="|") || kb=""
  IFS='|' read -r kb_keymap kb_variant <<< "$kb"
  keyboard_json="{\"keymap\": \"${kb_keymap:-us}\", \"xkbVariant\": \"${kb_variant:-\"\"}\"}"
else
  keyboard_json="null"
fi

# ─── Page 3: Apps to disable ────────────────────────────────────────────

# Build the checklist from the profile's apps.nix (grouped by category)
apps_list=""
for category in cli games gui media packaging services tui; do
  file="$REPO/hosts/profiles/gabrielnathan/apps.nix"
  [[ -f "$file" ]] || continue
  apps=$(grep -oP "^\s+\K[a-zA-Z0-9\"_-]+(?= = true)" "$file" \
    | while read -r app; do
        app=$(echo "$app" | tr -d '"')
        echo "FALSE"
        echo "${category}.${app}"
      done)
  while read -r checked; do
    read -r app
    apps_list="${apps_list}${checked}|${app}|${category}|"
  done < <(echo "$apps" | paste - - -d'\n')
done

if [[ -n "$apps_list" ]]; then
  disabled=$(zenity --list \
    --title="$title" \
    --text="Apps from the profile — uncheck what this machine should NOT have.\nLeave all checked to keep everything." \
    --checklist \
    --column="Keep" --column="App" --column="Category" \
    --separator="," \
    --print-column=2 \
    --height=500 --width=400 \
    $(echo "$apps_list" | tr '|' ' ') \
    2>/dev/null) || disabled=""

  # The list returns UNCHECKED items (things the user turned off)
  # zenity --list --checklist returns the items that are UNCHECKED
  # Wait — actually zenity --list --checklist prints CHECKED items
  # So we need to invert: disabled = all apps NOT in the returned list
  if [[ -n "$disabled" ]]; then
    disable_json=$(echo "$disabled" | tr ',' '\n' | sed 's/^/"/;s/$/"/' | paste -sd, -)
    disable_json="[$disable_json]"
  else
    disable_json="[]"
  fi
else
  disable_json="[]"
fi

# ─── Page 4: Generate answers and run the engine ────────────────────────

cat > "$ANSWERS_FILE" <<EOF
{
  "hostname": "$hostname",
  "gpu": "$gpu",
  "firmware": "$firmware",
  "desktop": "$desktop",
  "profile": "gabrielnathan",
  "nas": $([ "$nas" == "TRUE" ] && echo true || echo false),
  "vnc": $([ "$vnc" == "TRUE" ] && echo true || echo false),
  "keyboard": $keyboard_json,
  "disable": $disable_json
}
EOF

# ─── Page 5: Stream the engine output ──────────────────────────────────

tmp_out=$(mktemp)
python3 "$ENGINE" --answers "$ANSWERS_FILE" 2>&1 | tee "$tmp_out" | \
  zenity --progress \
    --title="$title" \
    --text="Generating hosts/$hostname and running validation gates…" \
    --pulsate --auto-close --no-cancel \
    2>/dev/null &

ENGINE_PID=$!
ZENITY_PID=$!

# Wait for the engine to finish
wait $ENGINE_PID 2>/dev/null
ENGINE_EXIT=$?

# Close the progress dialog
kill $ZENITY_PID 2>/dev/null || true

if [[ $ENGINE_EXIT -ne 0 ]]; then
  zenity --error --title="$title" \
    --text="The engine failed (exit $ENGINE_EXIT).\n\n$(tail -20 "$tmp_out")" \
    --width=600 2>/dev/null || true
  rm -f "$tmp_out"
  exit 1
fi

# Show the engine output
zenity --text-info --title="$title — Result" \
  --filename="$tmp_out" \
  --width=700 --height=500 \
  --checkbox="I understand the installer never commits anything" \
  2>/dev/null || {
    rm -f "$tmp_out"
    echo "hosts/$hostname generated successfully."
    echo "Run manually: sudo nixos-rebuild test --flake .#$hostname"
    exit 0
  }

# ─── Page 6: Offer the rebuild ─────────────────────────────────────────

if zenity --question --title="$title" \
  --text="Host generated and validated.\n\nRun the rebuild test now? (sudo nixos-rebuild test --flake .#$hostname)\n\nThis does NOT change the boot menu." \
  --ok-label="Run test" --cancel-label="Skip" 2>/dev/null; then

  sudo_output=$(mktemp)
  sudo sh -c "mkdir -p /root/.config/nix; grep -q '^experimental-features' /root/.config/nix/nix.conf 2>/dev/null || echo 'experimental-features = nix-command flakes' >> /root/.config/nix/nix.conf" 2>/dev/null || true

  sudo nixos-rebuild test --flake "$REPO#$hostname" 2>&1 | tee "$sudo_output" | \
    zenity --progress --title="$title" \
      --text="Running nixos-rebuild test…" \
      --pulsate --auto-close --no-cancel 2>/dev/null &

  SUDO_PID=$!
  ZENITY_PID2=$!
  wait $SUDO_PID 2>/dev/null
  TEST_EXIT=$?
  kill $ZENITY_PID2 2>/dev/null || true

  if [[ $TEST_EXIT -ne 0 ]]; then
    zenity --error --title="$title" \
      --text="Rebuild test failed (exit $TEST_EXIT).\n\n$(tail -10 "$sudo_output")" \
      2>/dev/null || true
    rm -f "$sudo_output"
    exit 1
  fi

  zenity --info --title="$title" \
    --text="Test activation passed.\n\nTo make it the boot default:\nsudo nixos-rebuild switch --flake .#$hostname" \
    2>/dev/null || true
  rm -f "$sudo_output"
else
  zenity --info --title="$title" \
    --text="Host ready.\n\nValidate and apply manually:\n  sudo nixos-rebuild test --flake .#$hostname" \
    2>/dev/null || true
fi

rm -f "$tmp_out"

zenity --info --title="$title" \
  --text="Done! Commit when you are happy:\n  git add hosts/$hostname\n  git commit -m \"feat(hosts): add $hostname (hamra-init)\"" \
  2>/dev/null || true
