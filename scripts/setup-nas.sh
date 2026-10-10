#!/usr/bin/env bash
#
# setup-nas — Wizard to install/recreate the NAS (Samba + secrets) on ANY PC
# using this Hamra repository.
#
# O que ele faz, em ordem:
#   1. Checks that the required tools exist.
#   2. Ensures this PC has a "host" registered in the repository.
#   3. Generates the secrets editing key (if it does not exist yet).
#   4. Registers this PC's keys in the ".sops.yaml" file.
#   5. Creates/renews the NAS password (it lives encrypted in secrets/samba.yaml).
#   6. Applies the configuration on this PC (optional).
#
# Modos:
#   ./scripts/setup-nas.sh              assistente completo (recomendado)
#   ./scripts/setup-nas.sh --check      environment check only (changes nothing)
#   ./scripts/setup-nas.sh --mostrar-senha   esqueceu a senha do NAS
#   ./scripts/setup-nas.sh --reset-senha    force creating a new password
#   ./scripts/setup-nas.sh --ajuda      esta ajuda
#
# Tip: run `nix develop` first — the environment already ships sops, age and ssh-to-age.
set -uo pipefail

trap '[[ -n "${REPO:-}" ]] && rm -f "$REPO/secrets/.tmp-samba.yaml"' EXIT INT TERM

# ---------------------------------------------------------------------------
# Colors (only when attached to a terminal)
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  _B=$'\033[1m'; _D=$'\033[2m'; _R=$'\033[31m'; _G=$'\033[32m'
  _Y=$'\033[33m'; _C=$'\033[36m'; _N=$'\033[0m'
else
  _B=""; _D=""; _R=""; _G=""; _Y=""; _C=""; _N=""
fi

info()  { printf "%s• %s%s\n" "$_C" "$*" "$_N"; }
title() {
  printf "\n%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$_B" "$_N"
  printf "%s  %s%s\n" "$_B" "$*" "$_N"
  printf "%s━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%s\n" "$_B" "$_N"
}
ok()    { printf "%s✔ %s%s\n" "$_G" "$*" "$_N"; }
warn()  { printf "%s⚠ %s%s\n" "$_Y" "$*" "$_N"; }
fail()  { printf "%s✖ %s%s\n" "$_R" "$*" "$_N"; }

die() {
  local help_msg="${_HELP:-}"
  fail "$1"
  if [[ -n $help_msg ]]; then
    printf "\n%sCOMO RESOLVER:%s\n" "$_B" "$_N"
    printf "%s\n" "$help_msg"
  fi
  printf "\nStill stuck? Run ./scripts/setup-nas.sh --ajuda\n"
  printf "or look for the \"NAS / Samba\" section in AGENTS.md.\n"
  exit "${2:-1}"
}

yesno() {
  local q="${1:-Continuar?}" d="${2:-s}" r
  printf "%s? [%s/n] " "$q" "$d"
  read -r r
  case "${r:-$d}" in
    [nN]|[nN][oO]) return 1 ;;
    *) return 0 ;;
  esac
}

ask() {
  local q="$1" d="${2:-}"
  printf "  %s" "$q"
  [[ -n $d ]] && printf " [%s]" "$d"
  printf ": "
  read -r REPLY
  [[ -z ${REPLY:-} && -n $d ]] && REPLY="$d"
}

# ---------------------------------------------------------------------------
# Available tools
# ---------------------------------------------------------------------------
declare -A TOOLS

collect_tools() {
  local t
  for t in nix sops age age-keygen ssh-to-age python3 git nixos-rebuild sudo; do
    if command -v "$t" >/dev/null 2>&1; then TOOLS[$t]=1; else TOOLS[$t]=0; fi
  done
}

require_tools() {
  local missing=() t
  for t in nix sops age age-keygen ssh-to-age python3 git; do
    (( TOOLS[$t] )) || missing+=("$t")
  done
  if ((${#missing[@]})); then
    _HELP="Rode o comando:  nix develop
(this repository's devShell already installs anything missing.)
Then run again:  ./scripts/setup-nas.sh"
    die "Faltam ferramentas: ${missing[*]}"
  fi
}

# Report (--check mode, changes nothing)
check_env() {
  title "Environment check --check"
  printf "  Repository  : %s\n" "$REPO"
  printf "  Directory   : %s\n" "$(pwd)"
  printf "\n  %-18s %s\n" "Ferramenta" "Status"
  for t in nix sops age age-keygen ssh-to-age python3 git nixos-rebuild sudo; do
    if (( TOOLS[$t] )); then
      printf "  %-18s %s\n" "$t" "ok ✔"
    else
      printf "  %-18s %s\n" "$t" "ausente ✖"
    fi
  done
  printf "\n  %sTip:%s run  nix develop  to get anything missing.\n" "$_B" "$_N"
}

# ---------------------------------------------------------------------------
# Find the repository
# ---------------------------------------------------------------------------
REPO=""

detect_repo() {
  local dir=""
  if [[ -n ${HAMRA_REPO:-} ]]; then
    dir="$HAMRA_REPO"
  elif [[ ${BASH_SOURCE[0]} == */scripts/setup-nas.sh ]]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  else
    dir="/etc/nixos"
  fi

  if [[ ! -f "$dir/scripts/setup-nas.sh" ]]; then
    _HELP="Clone the repository on this PC first. E.g.:
  git clone <url-do-repo> ~/Projetos/hamra
  sudo ln -s ~/Projetos/hamra /etc/nixos
Then run:  cd ~/Projetos/hamra && nix develop && ./scripts/setup-nas.sh"
    die "Could not find the Hamra repository at: $dir"
  fi
  REPO="$(cd "$dir" && pwd)"
  cd "$REPO" || die "Could not enter $REPO"
}

# ---------------------------------------------------------------------------
# Editing key (whoever is allowed to READ/EDIT the secrets)
# ---------------------------------------------------------------------------
AGE_KEYS="$HOME/.config/sops/age/keys.txt"
EDIT_PUB=""

ensure_edit_key() {
  title "Secrets editing key"
  info "The NAS password is stored ENCRYPTED in secrets/samba.yaml."
  info "To read/edit that file this PC needs an"
  info "editing key stored at: $AGE_KEYS"

  if [[ ! -f $AGE_KEYS ]]; then
    if ! yesno "No key here yet. Do you want to GENERATE one now"; then
      _HELP="Without the editing key you cannot read or reset the NAS password
from this PC. If you only want to USE the NAS (read/write files), you do not need it.
To ADMINISTER, copy the key from another PC (its ~/.config/sops/age/keys.txt)."
      die "No editing key available."
    fi
    mkdir -p "$(dirname "$AGE_KEYS")" || die "Could not create ~/.config/sops"
    chmod 700 "$(dirname "$AGE_KEYS")"
    age-keygen -o "$AGE_KEYS" || die "Failed to generate the editing key."
    chmod 600 "$AGE_KEYS"
    ok "Key created at $AGE_KEYS"
    warn "IMPORTANT: keep a copy somewhere safe (password manager)."
    warn "If you lose it, you will no longer be able to read/edit the NAS password."
  fi

  EDIT_PUB=$(age-keygen -y "$AGE_KEYS") || die "Could not read the editing key (age-keygen)."
  ok "Editing key OK (public: $EDIT_PUB)"
}

# ---------------------------------------------------------------------------
# Host key (derived from this PC's SSH key — decrypts the secrets at boot)
# ---------------------------------------------------------------------------
HOST_PUB=""

host_pubkey() {
  local ssh_pub=/etc/ssh/ssh_host_ed25519_key.pub
  [[ -f $ssh_pub ]] || {
    _HELP="This PC has no SSH host key at $ssh_pub.
On NixOS it is created automatically. If you are running another system
(e.g. Arch), installing this repository is a prerequisite."
    die "Could not find $ssh_pub"
  }
  if command -v ssh-to-age >/dev/null 2>&1; then
    HOST_PUB=$(cat "$ssh_pub" | ssh-to-age)
  else
    HOST_PUB=$(cat "$ssh_pub" | nix run nixpkgs#ssh-to-age 2>/dev/null)
  fi
  [[ $HOST_PUB =~ ^age1[0-9a-z]{50,}$ ]] || die "Failed to convert the SSH key into an age key."
  ok "This PC's key: $HOST_PUB"
}

# ---------------------------------------------------------------------------
# Register keys in .sops.yaml (safe insertion, preserves comments)
# ---------------------------------------------------------------------------
patch_sops_yaml() {
  python3 - "$REPO/.sops.yaml" "$1" <<'PYEOF'
import json, os, re, sys

path, data = sys.argv[1], json.loads(sys.argv[2])

anchor_re = re.compile(r'^\s*-\s*&([A-Za-z0-9_-]+)\s+(age1[0-9a-z]+)\s*$')
ref_re    = re.compile(r'^\s*-\s*\*([A-Za-z0-9_-]+)\s*$')

def skeleton():
    return ["keys:", "", "creation_rules:",
            "  - path_regex: secrets/.+\\.yaml$",
            "    key_groups:", "      - age:"]

lines = open(path).read().splitlines() if os.path.exists(path) else skeleton()
if not lines:
    lines = skeleton()

def scan():
    keys_idx = rules_idx = age_idx = last_anchor = last_ref = None
    anchors, by_key = {}, {}
    for i, ln in enumerate(lines):
        if re.match(r'^keys:\s*$', ln):          keys_idx = i
        if re.match(r'^creation_rules:\s*$', ln): rules_idx = i
        m = anchor_re.match(ln)
        if m and keys_idx is not None and (rules_idx is None or i < rules_idx):
            anchors[m.group(1)] = m.group(2)
            by_key[m.group(2)] = m.group(1)
            last_anchor = i
        m = ref_re.match(ln)
        if m and rules_idx is not None and i > rules_idx:
            last_ref = i
        if rules_idx is not None and i > rules_idx and re.match(r'^\s*- age:\s*$', ln):
            age_idx = i
    return keys_idx, rules_idx, age_idx, last_anchor, last_ref, anchors, by_key

added = []
for d in data:
    name, key = d["name"], d["key"]
    keys_idx, rules_idx, age_idx, last_anchor, last_ref, anchors, by_key = scan()

    if key in by_key:
        existing = by_key[key]
        if not any(ref_re.match(l) and ref_re.match(l).group(1) == existing for l in lines):
            at = (last_ref + 1) if last_ref is not None else (age_idx + 1 if age_idx is not None else rules_idx + 1)
            lines.insert(at, "          - *%s" % existing)
            added.append("*%s" % existing)
        continue

    aname, n = name, 2
    while aname in anchors:
        aname = "%s%d" % (name, n); n += 1
    anchor_line = "  - &%s %s" % (aname, key)
    if last_anchor is not None:
        lines.insert(last_anchor + 1, anchor_line)
    else:
        if keys_idx is None:
            lines.insert(0, "keys:")
            keys_idx = 0
        lines.insert(keys_idx + 1, anchor_line)
    added.append("&%s" % aname)

    keys_idx, rules_idx, age_idx, last_anchor, last_ref, anchors, by_key = scan()
    if age_idx is None:
        if rules_idx is None:
            lines.append("creation_rules:")
            rules_idx = len(lines) - 1
        lines.insert(rules_idx + 1, "  - path_regex: secrets/.+\\.yaml$")
        lines.insert(rules_idx + 2, "    key_groups:")
        lines.insert(rules_idx + 3, "      - age:")
        age_idx = rules_idx + 3
        last_ref = None
    at = (last_ref + 1) if last_ref is not None else (age_idx + 1)
    lines.insert(at, "          - *%s" % aname)
    added.append("*%s" % aname)

open(path, "w").write("\n".join(lines) + "\n")
print("Added: %s" % ", ".join(added) if added else "everything already registered")
PYEOF
}

# ---------------------------------------------------------------------------
# Ensure the host is registered in the repository
# ---------------------------------------------------------------------------
HOST_NAME=""
HOST_DIR=""
HOST_USER=""
HOST_EXISTS=0

ask_host() {
  title "Your PC in the Hamra repository"
  local cur name gpu firmware desktop user

  cur="$(hostname 2>/dev/null || echo meu-pc)"
  ask "Name of this PC inside the repository" "$cur"
  name="$REPLY"
  [[ $name =~ ^[a-zA-Z0-9-]+$ ]] || die "Invalid name (use only letters, numbers and hyphens)."

  HOST_NAME="$name"
  HOST_DIR="$REPO/hosts/$HOST_NAME"

  if [[ -f "$HOST_DIR/configuration.nix" ]]; then
    HOST_EXISTS=1
    ok "host \"$HOST_NAME\" already exists in hosts/$HOST_NAME — reusing it."
  else
    HOST_EXISTS=0
    info "This PC is not in the repository yet. I will create its structure."
    info "Answer a few questions to build the configuration file."

    ask "PC GPU (intel | amd | nvidia | virtio)" "intel"
    case "$REPLY" in
      intel|amd|nvidia|virtio) gpu="$REPLY" ;;
      *) die "Invalid GPU \"$REPLY\". Use: intel, amd, nvidia or virtio."
    esac

    ask "Firmware (uefi | bios)" "uefi"
    case "$REPLY" in
      uefi|bios) firmware="$REPLY" ;;
      *) die "Invalid firmware \"$REPLY\". Use: uefi or bios."
    esac

    ask "Desktop (hyprland | sway | niri | gnome | plasma)" "hyprland"
    case "$REPLY" in
      hyprland|sway|niri|gnome|plasma) desktop="$REPLY" ;;
      *) die "Invalid desktop \"$REPLY\". Use: hyprland, sway, niri, gnome or plasma."
    esac

    info "Samba will be ENABLED on this host (it is the NAS)."
    HOST_GPU="$gpu"; HOST_FIRMWARE="$firmware"; HOST_DESKTOP="$desktop"
  fi

  ask "Your system username inside NixOS" "${USER:-gabrielnathan}"
  user="$REPLY"
  [[ $user =~ ^[a-z][a-z0-9]*$ ]] || die "Invalid username (lowercase letters and numbers)."
  HOST_USER="$user"
}

create_host() {
  mkdir -p "$HOST_DIR" || die "Could not create hosts/$HOST_NAME"

  info "Gerando hardware-configuration.nix (detecta CPU, placa, discos...)..."
  if (( EUID != 0 )) && (( TOOLS[sudo] )); then
    # The redirect is done by the shell (file stays owned by the user); only the detection needs root.
    # shellcheck disable=SC2024
    sudo -p "Sudo password to detect the hardware: " \
      nixos-generate-config --show-hardware-config > "$HOST_DIR/hardware-configuration.nix" \
      || die "Falha ao gerar o hardware-configuration.nix (sudo)."
  else
    nixos-generate-config --show-hardware-config > "$HOST_DIR/hardware-configuration.nix" \
      || die "Falha ao gerar o hardware-configuration.nix."
  fi
  ok "hardware-configuration.nix criado."

  local answers
  answers="$(mktemp)" || die "Could not create temp answers file."
  cat > "$answers" <<ANSWERS
{
  "hostname": "$HOST_NAME",
  "username": "$HOST_USER",
  "gpu": "$HOST_GPU",
  "firmware": "$HOST_FIRMWARE",
  "desktop": "$HOST_DESKTOP",
  "nas": true,
  "vnc": false
}
ANSWERS

  HAMRA_REPO="$REPO" bash "$REPO/scripts/cookiecutter.sh" \
    --answers "$answers" --render-into "$HOST_DIR" \
    || { rm -f "$answers"; die "cookiecutter could not render the host files."; }
  rm -f "$answers"

  ok "host \"$HOST_NAME\" created (hosts under hosts/ are discovered by scan; no manual registration). Files:"
  printf "    %s\n" "$HOST_DIR"/configuration.nix "$HOST_DIR"/config/system.nix "$HOST_DIR"/config/hardware.nix "$HOST_DIR"/config/desktop.nix "$HOST_DIR"/config/programs-core.nix "$HOST_DIR"/config/programs-optionals.nix "$HOST_DIR"/config/home.nix "$HOST_DIR/hardware-configuration.nix"
}

ensure_samba_enabled() {
  local cfg="$HOST_DIR/config/programs-optionals.nix"
  if grep -qE 'samba[[:space:]]*=[[:space:]]*true' "$cfg"; then
    ok "Samba is already enabled on host \"$HOST_NAME\"."
    return 0
  fi
  if grep -q 'samba' "$cfg"; then
    sed -i '0,/samba[[:space:]]*=[[:space:]]*false/s//samba = true/' "$cfg"
    ok "Samba ativado no host \"$HOST_NAME\"."
    return 0
  fi
  warn "Could not find the 'samba' line in the host file."
  warn "Add it manually inside hamra.programs.optionals.services:"
  printf "      services = {\n        wayvnc = false;\n        samba = true;\n      };\n"
}

# ---------------------------------------------------------------------------
# NAS password (create / keep / change)
# ---------------------------------------------------------------------------
NAS_PASSWORD=""

read_password() {
  local p1 p2
  while :; do
    printf "  Type the NAS password (not shown on screen): "
    read -rs p1; printf "\n"
    if (( ${#p1} < 8 )); then
      warn "The password needs at least 8 characters."; continue
    fi
    printf "  Confirm the password: "
    read -rs p2; printf "\n"
    if [[ $p1 != "$p2" ]]; then
      warn "Passwords do not match. Try again."; continue
    fi
    break
  done
  NAS_PASSWORD="$p1"
  p1=""; p2=""
}

write_secret() {
  # sops picks the encryption rule by the PATH of the input file.
  # That is why the temporary plaintext stays in secrets/ (matching the
  # creation_rules "secrets/.+\.yaml$") and is deleted right after.
  local tmpf="$REPO/secrets/.tmp-samba.yaml"
  [[ -w secrets ]] || {
    _HELP="The secrets/ directory is not writable. Check its owner:
  ls -ld secrets
Se preciso:  sudo chown -R \$(whoami):users secrets"
    die "Cannot write to secrets/."
  }
  rm -f "$tmpf"
  printf "samba-password: '%s'\n" "${NAS_PASSWORD//\'/\'\'}" > "$tmpf"
  chmod 600 "$tmpf"

  if ! sops --encrypt --input-type yaml --output-type yaml \
      --output secrets/samba.yaml "$tmpf"; then
    rm -f "$tmpf"
    _HELP="sops uses the .sops.yaml file (created in the previous step) to pick
for whoever encrypts. Check that .sops.yaml has a creation_rules section."
    die "Failed to encrypt the password."
  fi
  rm -f "$tmpf"

  if ! sops --decrypt secrets/samba.yaml > /dev/null 2>&1; then
    _HELP="The password was encrypted, but I could not re-read it now.
Run:  nix develop && ./scripts/setup-nas.sh"
    die "Failed to verify the encrypted file."
  fi
  ok "password securely encrypted in secrets/samba.yaml"
}

handle_password() {
  title "NAS password"
  local secret_file="secrets/samba.yaml"

  if [[ -f $secret_file && ${FORCE_RESET:-0} == 0 ]]; then
    info "There is already an encrypted password in secrets/samba.yaml."
    if yesno "Keep the current password"; then
      ok "Current password kept."
      return 0
    fi
  fi

  if [[ -f $secret_file ]]; then
    info "The old password will be REPLACED. This changes NAS access
    from the NEXT time this host is applied on NixOS."
    info "Remember to update the credential on the clients "
    info "(e.g. the cred-nas file used in other PCs' /etc/fstab)."
  fi

  read_password
  write_secret

  if [[ -f $secret_file ]]; then
    info "Syncing recipients (for every registered PC"
    info "conseguirem decriptar no boot)..."
    printf 'y\n' | sops updatekeys secrets/samba.yaml >/dev/null \
      || warn "updatekeys failed — other machines may fail to apply."
    ok "Recipients synced."
  fi
}

# ---------------------------------------------------------------------------
# Aplicar no PC (opcional)
# ---------------------------------------------------------------------------
deploy() {
  title "Aplicar no PC (nixos-rebuild)"
  if [[ ${TOOLS[nixos-rebuild]} == 0 ]]; then
    warn "This PC has no nixos-rebuild (NixOS only)."
    warn "This machine may be JUST A NAS CLIENT (reads/writes the files)."
    return 0
  fi
  if ! yesno "Apply the configuration on this PC now (recommended)"; then
    info "You can apply later with:"
    printf "  sudo nixos-rebuild switch --flake %s#%s\n" "$REPO" "$HOST_NAME"
    return 0
  fi

  if (( EUID != 0 )) && (( TOOLS[sudo] )); then
    if ! sudo -p "Sudo password to apply the configuration: " -v; then
      _HELP="Could not validate the sudo password. Run it yourself as root:
  sudo nixos-rebuild switch --flake $REPO#$HOST_NAME"
      die "Sudo unavailable."
    fi
    sudo nixos-rebuild switch --flake "$REPO#$HOST_NAME"
    local rc=$?
  else
    nixos-rebuild switch --flake "$REPO#$HOST_NAME"
    local rc=$?
  fi

  if (( rc != 0 )); then
    _HELP="O rebuild falhou. Leia o erro acima. Causas comuns:
  • hardware-configuration.nix with wrong UUID/device (do not change UUIDs).
  • NAS password too short for the server to accept.
After fixing, run again: sudo nixos-rebuild switch --flake $REPO#$HOST_NAME"
    die "Failed to apply the configuration."
  fi
  ok "Configuration applied! Samba is (or will be after reboot) active."
}

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------
summary() {
  title "Resumo — tudo pronto"
  if [[ -n ${NAS_PASSWORD:-} ]]; then
    info "NAS password for this repository (yours, just created):"
    printf "\n    %s%s%s\n\n" "$_B" "$NAS_PASSWORD" "$_N"
  fi

  printf "  %sNAS usage:%s\n" "$_B" "$_N"
  printf "    - Linux (mount):    \\\\acer\\shared in the file manager (user + NAS password)\n"
  printf "    - Windows:  open \\\\\\\\<host-ip>\\\\shared in File Explorer\n"
  printf "    - Mac:      Conectar ao servidor -> smb://<ip-do-host>/shared\n"
  printf "  %sGerenciar:%s\n" "$_B" "$_N"
  printf "    - Ver a senha de novo:   ./scripts/setup-nas.sh --mostrar-senha\n"
  printf "    - Trocar a senha:        ./scripts/setup-nas.sh --reset-senha\n"
  printf "    - Adicionar outro PC:    rode este script de novo NAQUELE PC\n"
  printf "  %sPublish to the repository:%s\n" "$_B" "$_N"
  printf "    git add -A && git commit -m \"Add NAS setup\" && git push\n"
  NAS_PASSWORD=""
}

# ---------------------------------------------------------------------------
# Forgotten password
# ---------------------------------------------------------------------------
show_password() {
  detect_repo
  cd "$REPO" || die "Could not enter $REPO"
  if [[ ! -f secrets/samba.yaml ]]; then
    _HELP="No saved password yet. Run ./scripts/setup-nas.sh"
    die "No secret created yet."
  fi
  title "NAS password"
  info "One moment... (requires the editing key OR the SSH key of a host"
  info "registered on this PC — on NixOS this is automatic)."
  if ! out=$(sops --decrypt secrets/samba.yaml 2>&1); then
    _HELP="Could not decrypt. The file only opens with:
  1) the editing key at ~/.config/sops/age/keys.txt; OR
  2) a NixOS PC with its SSH host key registered in .sops.yaml.
If you have none of them, ask someone with access to add
this PC's key and run:  printf 'y\\n' | sops updatekeys secrets/samba.yaml"
    die "Failed to decrypt the secret."
  fi
  printf "\n    %s%s%s\n\n" "$_B" "$out" "$_N"
}

# ---------------------------------------------------------------------------
# Ajuda
# ---------------------------------------------------------------------------
ajuda() {
  title "setup-nas — ajuda"
  sed -n '2,28p' "$0"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
collect_tools
FORCE_RESET=0

case "${1:-}" in
  -h|--ajuda|--help|help) ajuda; exit 0 ;;
  --check) detect_repo; check_env; exit 0 ;;
  --mostrar-senha) require_tools; show_password; exit 0 ;;
  --reset-senha) FORCE_RESET=1 ;;
esac

require_tools
detect_repo

title "Welcome to the NAS setup"
info "This wizard prepares this PC to be a NAS (Samba) using this"
info "Hamra repository. It explains each step and shows what to do if"
info "something goes wrong."
info ""
if ! yesno "Shall we begin"; then echo "Goodbye!"; exit 0; fi

ask_host
if (( HOST_EXISTS == 0 )); then
  create_host
else
  ensure_samba_enabled
fi

ensure_edit_key
host_pubkey

title "Key registration in .sops.yaml"
info "Adding the editing key and this PC key to .sops.yaml..."
if out=$(patch_sops_yaml "[{\"name\":\"user\",\"key\":\"$EDIT_PUB\"},{\"name\":\"host-$HOST_NAME\",\"key\":\"$HOST_PUB\"}]"); then
  ok ":: $out"
else
  _HELP="Error editing .sops.yaml. See the key-registration notes
in SETUP.md (section 3) and adjust manually if needed."
  die "Could not modify .sops.yaml."
fi

handle_password
deploy
summary