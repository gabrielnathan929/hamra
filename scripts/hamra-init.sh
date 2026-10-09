#!/usr/bin/env bash
#  ██╗  ██╗ █████╗ ███╗   ██╗ █████╗
#  ██║  ██║██╔══██╗████╗  ██║██╔══██╗
#  ███████║███████║██╔██╗ ██║███████║
#  ██╔══██║██╔══██║██║╚██╗██║██╔══██║
#  ██║  ██║██║  ██║██║ ╚████║██║  ██║
#  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
#
#  hamra-init — generate an atomic Hamra host, validate it, guide the rebuild.
#
#  Each host is self-contained: hosts/<name>/ carries identity, system choices
#  and the full true/false menus, split by toggle type under config/. Toggle
#  universes and their defaults come from the module files themselves via
#  scripts/hamra-render.nix (a single nix eval), so generation can never drift
#  from the toggle modules.
#
#  Usage:
#    hamra-init                       interactive wizard
#    hamra-init --answers a.json      non-interactive
#    hamra-init --dry-run             print the files, write nothing
#    hamra-init --render-only         print the files to stdout (golden-test mode)
#    hamra-init --render-into DIR     write the host files into DIR
#    hamra-init --check               read-only environment audit
#    hamra-init --gates-only <host>   re-run the validation gates for a host

set -u

CRE=$(tput setaf 1 2>/dev/null || true)
CYE=$(tput setaf 3 2>/dev/null || true)
CGR=$(tput setaf 2 2>/dev/null || true)
CBL=$(tput setaf 4 2>/dev/null || true)
BLD=$(tput bold 2>/dev/null || true)
CNC=$(tput sgr0 2>/dev/null || true)

MIN_FREE_GB=5
WARN_FREE_GB=15
HOST_FILE_ORDER=(
  "configuration.nix"
  "config/system.nix"
  "config/hardware.nix"
  "config/desktop.nix"
  "config/programs-core.nix"
  "config/programs-optionals.nix"
  "config/home.nix"
)

REPO="${HAMRA_REPO:-$PWD}"
ANSWERS=""
DRY_RUN=0
RENDER_ONLY=0
RENDER_INTO=""
CHECK=0
GATES_ONLY=""
EXTRA_ENABLE=""
EXTRA_DISABLE=""

die() {
    printf "%b\n" "${BLD}${CRE}error:${CNC} $1" >&2
    [ -n "${2:-}" ] && printf "%b\n" "$2" >&2
    exit 1
}
info() { printf "  %b\n" "$1"; }
ok() { printf "%b\n" "${BLD}${CGR}ok:${CNC} $1"; }
warn() { printf "%b\n" "${BLD}${CYE}warn:${CNC} $1" >&2; }

logo() {
    text="$1"
    printf "%b" "
${CGR}  ██╗  ██╗ █████╗ ███╗   ██╗ █████╗ ${CNC}
${CGR}  ██║  ██║██╔══██╗████╗  ██║██╔══██╗${CNC}
${CGR}  ███████║███████║██╔██╗ ██║███████║${CNC}
${CGR}  ██╔══██║██╔══██║██║╚██╗██║██╔══██║${CNC}
${CGR}  ██║  ██║██║  ██║██║ ╚████║██║  ██║${CNC}
${CGR}  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝${CNC}

 ${BLD}${CRE}[ ${CYE}${text} ${CRE}]${CNC}
" 2>/dev/null
}

step() {
    clear 2>/dev/null
    logo "$1"
    sleep 1
}

ask_input() {
    label="$1"; default="${2:-}"
    if [ -n "$default" ]; then
        printf " %b" "${BLD}${CYE}${label}${CNC} [${default}]: "
    else
        printf " %b" "${BLD}${CYE}${label}${CNC}: "
    fi
    read -r raw
    raw="${raw:-$default}"
    printf "%s" "$raw"
}

ask_yes_no() {
    label="$1"; default="${2:-false}"
    case "$default" in
        true) suffix="[Y/n]" ;;
        *) suffix="[y/N]" ;;
    esac
    while :; do
        printf " %b" "${BLD}${CYE}${label}${CNC} $suffix: "
        read -r yn
        case "$yn" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            "") case "$default" in true) return 0 ;; *) return 1 ;; esac ;;
        esac
    done
}

ask_enum() {
    label="$1"; default="$2"; shift 2
    opts="$*"
    display=$(printf "%s | " "$@")
    display="${display% | }"
    while :; do
        printf " %b" "${BLD}${CYE}${label}${CNC} (${display}) [${default}]: "
        read -r raw
        raw="${raw:-$default}"
        for o in "$@"; do
            [ "$raw" = "$o" ] && { printf "%s" "$raw"; return 0; }
        done
        warn "'$raw' is not one of: $display"
    done
}

render_expr() {
    printf "import %s/scripts/hamra-render.nix { answersFile = \"%s\"; repoPath = \"%s\"; }" "$REPO" "$1" "$REPO"
}

run_renderer() {
    answers_file="$1"
    command -v jq > /dev/null 2>&1 \
        || die "jq is required (nix shell nixpkgs#jq or nix develop)"
    nix eval --impure --json --expr "$(render_expr "$answers_file")" \
        || die "nix render failed"
}

write_rendered() {
    outdir="$1"; json="$2"
    mkdir -p "$outdir/config"
    for f in "${HOST_FILE_ORDER[@]}"; do
        jq -j --arg f "$f" '.files[$f]' <<< "$json" > "$outdir/$f"
    done
}

print_rendered() {
    hostname="$1"; json="$2"
    for f in "${HOST_FILE_ORDER[@]}"; do
        printf "\n===== hosts/%s/%s =====\n" "$hostname" "$f"
        jq -r --arg f "$f" '.files[$f]' <<< "$json"
    done
}

scanned_hosts() {
    find "$REPO/hosts" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%f\n' 2>/dev/null | sort
}

check_dirty_targets() {
    hostname="$1"
    [ -d "$REPO/.git" ] || return 0
    if [ -n "$(git -C "$REPO" status --porcelain -- "hosts/$hostname")" ]; then
        die "target files have uncommitted changes — hamra-init refuses to risk your work" \
            "git status -- hosts/$hostname is not clean. Commit or stash them first."
    fi
}

check_disk() {
    free_gb=$(df -BG --output=avail "$REPO" 2>/dev/null | tail -1 | tr -dc '0-9')
    [ -n "${free_gb:-}" ] || return 0
    if [ "$free_gb" -lt "$MIN_FREE_GB" ]; then
        die "only ${free_gb} GB free — a first build needs more"
    fi
    [ "$free_gb" -lt "$WARN_FREE_GB" ] && warn "only ${free_gb} GB free — the first build downloads a lot"
    return 0
}

check_user() {
    username="$1"
    [ "$username" = "$(id -un)" ] && return 0
    warn "answers user is '$username' but you are '$(id -un)'"
    printf "  type '%s' to confirm anyway: " "$username"
    read -r confirm
    [ "$confirm" = "$username" ] || die "aborted — use a username matching this machine's user"
}

sops_gate() {
    nix develop --command sops -d "$REPO/secrets/samba.yaml" > /dev/null 2>&1 \
        || die "the samba secret cannot be decrypted on this machine" \
            "The rebuild would fail at activation. Register this machine's key first:
  nix develop && ./scripts/setup-nas.sh
Or leave the NAS role off."
    ok "sops secret decrypts on this machine"
}

gate() {
    printf "\n── gate: %s \n" "$1"
    shift
    "$@" || die "gate failed"
}

run_gates() {
    hostname="$1"; offer_rebuild="$2"
    lint=""
    for f in "${HOST_FILE_ORDER[@]}"; do
        lint+="alejandra --check hosts/$hostname/$f && statix check hosts/$hostname/$f && deadnix hosts/$hostname/$f && "
    done
    lint="${lint% && }"
    gate "format + lint" nix develop --command sh -c "$lint"
    gate "nix flake check" nix flake check
    gate "nix build toplevel" nix build --no-link ".#nixosConfigurations.$hostname.config.system.build.toplevel"
    [ "$offer_rebuild" = "1" ] || return 0

    printf "\n%b\n" "${BLD}${CGR}All gates passed. Next: activate without touching the boot menu.${CNC}"
    printf "%b\n" "You can roll back with: ${CBL}sudo nixos-rebuild switch --rollback${CNC}"
    if ask_yes_no "Run 'sudo nixos-rebuild test' now?" "false"; then
        enable_flakes_root
        sudo nixos-rebuild test --flake ".#$hostname" \
            || die "nixos-rebuild test failed"
        ok "test activation done"
        printf "\nIf the machine looks good, make it the boot default:\n"
        printf "  type '%s' to run the switch: " "$hostname"
        read -r typed
        if [ "$typed" = "$hostname" ]; then
            sudo nixos-rebuild switch --flake ".#$hostname" \
                || die "nixos-rebuild switch failed"
            ok "switch done — this generation is the new boot default"
        else
            printf "  skipped. Run it yourself with:\n"
            printf "  sudo nixos-rebuild switch --flake .#%s\n" "$hostname"
        fi
    else
        printf "  skipped. Run it yourself with:\n"
        printf "  sudo nixos-rebuild test --flake .#%s\n" "$hostname"
    fi
}

write_host() {
    hostname="$1"; json="$2"; hardware="$3"
    final="$REPO/hosts/$hostname"
    [ -e "$final" ] && die "hosts/$hostname already exists — write-once rule; nothing was written"
    tmp=$(mktemp -d "$REPO/hosts/.${hostname}.tmp-XXXXXX")
    write_rendered "$tmp" "$json"
    printf "%s" "$hardware" > "$tmp/hardware-configuration.nix"
    command -v alejandra > /dev/null 2>&1 && alejandra -q "$tmp" 2>/dev/null
    mv "$tmp" "$final"
    ok "hosts/$hostname/ created (atomic)"
}

hardware_config_source() {
    for c in /etc/nixos.pre-hamra/hardware-configuration.nix /etc/nixos/hardware-configuration.nix; do
        if [ -f "$c" ] && ! readlink -f "$c" 2>/dev/null | grep -q hamra; then
            printf "%s" "$(cat "$c")"
            return 0
        fi
    done
    gen=$(command -v nixos-generate-config || true)
    if [ -n "$gen" ]; then
        "$gen" --show-hardware-config
        return 0
    fi
    nix shell nixpkgs#nixos-install-tools -c nixos-generate-config --show-hardware-config
}

detect_gpu() {
    command -v lspci > /dev/null 2>&1 || return 0
    out=$(lspci 2>/dev/null | tr '[:upper:]' '[:lower:]')
    if grep -q virtio <<<"$out" && grep -qE "vga|display" <<<"$out"; then printf "virtio"; return 0; fi
    grep -q nvidia <<<"$out" && { printf "nvidia"; return 0; }
    grep -qE "amd|ati.*radeon" <<<"$out" && { printf "amd"; return 0; }
    grep -q intel <<<"$out" && { printf "intel"; return 0; }
    return 0
}

detect_firmware() {
    if [ -d /sys/firmware/efi ]; then printf "uefi"; else printf "bios"; fi
}

ask_hostname() {
    existing="$1"
    while :; do
        hostname=$(ask_input "Machine name (becomes hostname and hosts/<name>)" "")
        case "$hostname" in
            ""|*[!a-zA-Z0-9-]*)
                warn "use letters, numbers and hyphens (must not start with a hyphen)"; continue ;;
            -*) warn "must not start with a hyphen"; continue ;;
        esac
        case "$hostname" in common|profiles) warn "'common' and 'profiles' are reserved"; continue ;; esac
        if grep -qx "$hostname" <<<"$existing"; then
            warn "hosts/$hostname already exists — hamra-init never overwrites (write-once)"; continue
        fi
        printf "%s" "$hostname"
        return 0
    done
}

ask_app_list() {
    label="$1"
    printf " %b\n" "${BLD}${CYE}${label}${CNC} (comma-separated cat.app, empty = defaults): "
    read -r raw
    raw="${raw// /}"
    [ -z "$raw" ] && return 0
    printf "%s" "$raw" | tr ',' '\n'
}

build_answers() {
    username="$1"; hostname="$2"; locale="$3"; timezone="$4"; theme="$5"
    gpu="$6"; firmware="$7"; desktop="$8"; displayManager="$9"; keyboard="${10}"
    nas="${11}"; vnc="${12}"; env_editor="${13}"; env_browser="${14}"
    env_terminal="${15}"; env_filemanager="${16}"; enable_list="${17}"
    core_disable_list="${18}"; hm_enable_list="${19}"

    json_list() {
        [ -z "${1:-}" ] && { printf "[]"; return 0; }
        printf "["
        first=1
        printf "%s" "$1" | tr ',' '\n' | while IFS= read -r item; do
            [ -z "$item" ] && continue
            if [ $first -eq 1 ]; then first=0; else printf ", "; fi
            printf '"%s"' "$item"
        done
        printf "]"
    }

    keyboard_json="null"
    if [ "$keyboard" != "null" ]; then
        IFS='|' read -r keymap variant <<< "$keyboard"
        if [ -n "$variant" ]; then
            keyboard_json="{\"keymap\": \"$keymap\", \"xkbVariant\": \"$variant\"}"
        else
            keyboard_json="{\"keymap\": \"$keymap\"}"
        fi
    fi

    printf '{
  "hostname": "%s",
  "username": "%s",
  "locale": "%s",
  "timezone": "%s",
  "theme": "%s",
  "gpu": "%s",
  "firmware": "%s",
  "desktop": "%s",
  "displayManager": "%s",
  "keyboard": %s,
  "nas": %s,
  "vnc": %s,
  "env": {
    "editor": "%s",
    "browser": "%s",
    "terminal": "%s",
    "filemanager": "%s"
  },
  "enable": %s,
  "core_disable": %s,
  "hm_enable": %s
}' \
        "$hostname" "$username" "$locale" "$timezone" "$theme" \
        "$gpu" "$firmware" "$desktop" "$displayManager" "$keyboard_json" \
        "$nas" "$vnc" \
        "$env_editor" "$env_browser" "$env_terminal" "$env_filemanager" \
        "$(json_list "$enable_list")" "$(json_list "$core_disable_list")" "$(json_list "$hm_enable_list")"
}

validate_answers() {
    answers_file="$1"
    jq -e . "$answers_file" > /dev/null 2>&1 \
        || die "cannot parse answers file as JSON"
    for key in hostname username gpu firmware desktop nas vnc; do
        jq -e --arg k "$key" 'has($k)' "$answers_file" > /dev/null \
            || die "answers file is missing keys: $key"
    done
    hostname=$(jq -r .hostname "$answers_file")
    username=$(jq -r .username "$answers_file")
    case "$hostname" in
        ""|*[!a-zA-Z0-9-]*|-*) die "invalid hostname '$hostname' (letters, numbers, hyphens)" ;;
    esac
    case "$hostname" in common|profiles) die "'common' and 'profiles' are reserved names" ;; esac
    if [ -d "$REPO/hosts/$hostname" ]; then
        die "hosts/$hostname already exists — hamra-init never overwrites (write-once)"
    fi
    case "$username" in
        ""|*[!a-z0-9_-]*) die "invalid username '$username'" ;;
    esac
    case "$username" in [0-9]*) die "invalid username '$username'" ;; esac
    for key in locale timezone theme; do
        v=$(jq -r --arg k "$key" '.[$k] // ""' "$answers_file")
        case "$v" in *\"*|*\\*) die "'$key' must not contain quotes or backslashes" ;; esac
    done
    gpu=$(jq -r .gpu "$answers_file")
    firmware=$(jq -r .firmware "$answers_file")
    desktop=$(jq -r .desktop "$answers_file")
    dm=$(jq -r '.displayManager // ""' "$answers_file")
    enums=$(nix eval --json --file "$REPO/modules/lib/enums.nix" 2>/dev/null) \
        || die "could not read modules/lib/enums.nix"
    for pair in "gpus:gpu:$gpu" "firmware:firmware:$firmware" "desktops:desktop:$desktop"; do
        list="${pair%%:*}"
        rest="${pair#*:}"
        label="${rest%%:*}"
        value="${rest#*:}"
        echo "$enums" | jq -e --arg l "$list" --arg v "$value" '.[$l] | index($v) != null' > /dev/null \
            || die "invalid $label '$value'"
    done
    if [ -n "$dm" ]; then
        echo "$enums" | jq -e --arg v "$dm" '.displayManagers | index($v) != null' > /dev/null \
            || die "invalid displayManager '$dm'"
    fi
    for key in editor browser terminal filemanager; do
        v=$(jq -rn --arg k "$key" --slurpfile a "$answers_file" '$a[0].env[$k] // ""')
        [ -z "$v" ] && continue
        case "$v" in
            *[!a-zA-Z0-9_.-]*) die "env.$key must be a nixpkgs attribute name like 'foot'" ;;
        esac
    done
    if [ "$(jq -r .vnc "$answers_file")" = "true" ]; then
        case "$desktop" in hyprland|sway) ;; *) die "wayvnc requires desktop hyprland or sway (assertion rule)" ;; esac
    fi
    keymap=$(jq -r '.keyboard.keymap // ""' "$answers_file")
    [ "$(jq -r 'has("keyboard")' "$answers_file")" = "true" ] \
        && [ "$(jq -r '.keyboard != null' "$answers_file")" = "true" ] \
        && [ -z "$keymap" ] \
        && die "keyboard.keymap cannot be empty when keyboard is set"
    return 0
}

collect_answers() {
    step "Welcome $(id -un)"
    printf "%b\n" "${BLD}${CGR}This wizard generates a complete Hamra host. It will:${CNC}

  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Ask identity, hardware, desktop and role questions
  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Render ${CBL}hosts/<name>/${CNC} with the FULL toggle menus from the modules
  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Run the gates: alejandra + statix + deadnix, flake check, build
  ${BLD}${CGR}[${CYE}i${CGR}]${CNC} Offer the rebuild (test first, switch on confirmation)

${BLD}${CRE}[${CYE}!${CRE}]${CNC} ${BLD}${CRE}It never overwrites an existing host (write-once)${CNC}
"
    ask_yes_no "Do you wish to continue?" "true" || { printf "\nOperation cancelled\n"; exit 0; }

    step "Identity"
    HOSTNAME_ANSWER=$(ask_hostname "$(scanned_hosts)")
    username=$(ask_input "Username" "$(id -un)")
    while :; do
        case "$username" in
            ""|*[!a-z0-9_-]*|[0-9]*) warn "use lowercase letters, numbers, hyphen or underscore" ;;
            *) break ;;
        esac
        username=$(ask_input "Username" "$(id -un)")
    done
    fullName=$(ask_input "Full name" "Gabriel Nathan dos Santos Pires")
    email=$(ask_input "Email" "devgabrielnathan@gmail.com")

    step "Locale and theme"
    locale=$(ask_input "Locale" "pt_BR.UTF-8")
    timezone=$(ask_input "Timezone" "America/Sao_Paulo")
    theme=$(ask_input "Theme" "dragon-ball")

    step "Hardware"
    detected_gpu=$(detect_gpu)
    [ -n "$detected_gpu" ] || detected_gpu="intel"
    gpu=$(ask_enum "GPU" "$detected_gpu" intel amd nvidia virtio)
    firmware=$(ask_enum "Firmware" "$(detect_firmware)" uefi bios)
    if ask_yes_no "Custom keyboard? (default is br/abnt2)" "false"; then
        keymap=$(ask_input "  keymap (e.g. us, br)" "us")
        variant=$(ask_input "  xkbVariant (e.g. intl, abnt2 — empty for none)" "")
        keyboard="$keymap|$variant"
    else
        keyboard="null"
    fi

    step "Desktop"
    desktop=$(ask_enum "Desktop" "hyprland" hyprland sway niri gnome plasma)
    displayManager=$(ask_enum "Display manager" "sddm" sddm greetd)

    step "Host role"
    nas="false"
    ask_yes_no "Is this machine the NAS (Samba)?" "false" && nas="true"
    vnc="false"
    ask_yes_no "Run the wayvnc server here?" "false" && vnc="true"
    if [ "$vnc" = "true" ] && [ "$desktop" != "hyprland" ] && [ "$desktop" != "sway" ]; then
        warn "wayvnc needs hyprland or sway — turning it off"
        vnc="false"
    fi

    step "Default apps"
    env_editor=$(ask_input "Editor package" "neovim")
    env_browser=$(ask_input "Browser package" "chromium")
    env_terminal=$(ask_input "Terminal package" "foot")
    env_filemanager=$(ask_input "File manager package" "thunar")

    step "Toggles"
    info "Core toggles default ON, optionals default OFF — every toggle is written to the host."
    enable_list=$(ask_app_list "Optional apps to enable" | tr '\n' ',')
    core_disable_list=$(ask_app_list "Core apps to disable" | tr '\n' ',')
    hm_enable_list=$(ask_app_list "Home (HM) apps to enable" | tr '\n' ',')

    build_answers "$username" "$HOSTNAME_ANSWER" "$locale" "$timezone" "$theme" \
        "$gpu" "$firmware" "$desktop" "$displayManager" "$keyboard" \
        "$nas" "$vnc" "$env_editor" "$env_browser" "$env_terminal" "$env_filemanager" \
        "$enable_list" "$core_disable_list" "$hm_enable_list" \
        > "$ANSWERS"
}

ensure_flakes_user() {
    conf="$HOME/.config/nix/nix.conf"
    mkdir -p "$(dirname "$conf")"
    if ! grep -q "experimental-features" "$conf" 2>/dev/null; then
        printf "experimental-features = nix-command flakes\n" >> "$conf"
        ok "enabled flakes for the user ($conf)"
    fi
    if grep -q "experimental-features" "$conf" 2>/dev/null && ! grep -q "nix-command flakes" "$conf"; then
        warn "$conf sets experimental-features without nix-command flakes — the bootstrap flag will be needed for now"
    fi
}

enable_flakes_root() {
    sudo sh -c "mkdir -p /root/.config/nix; grep -q '^experimental-features' /root/.config/nix/nix.conf 2>/dev/null || echo 'experimental-features = nix-command flakes' >> /root/.config/nix/nix.conf"
    ok "flakes enabled for root (one-time)"
}

offer_etc_nixos_symlink() {
    target="/etc/nixos"
    if [ -L "$target" ]; then
        [ "$(readlink -f "$target")" = "$(readlink -f "$REPO")" ] && return 0
        warn "/etc/nixos symlinks to $(readlink -f "$target") (not this checkout)"
        return 0
    fi
    if [ -e "$target" ]; then
        backup="/etc/nixos.pre-hamra"
        printf "\nOne-time setup (runs with sudo): back up the installer's /etc/nixos\n"
        printf "to %s and symlink this checkout in its place. This is what\n" "$backup"
        printf "makes plain nixos-rebuild and setup-nas find the repository.\n"
        ask_yes_no "Do it now?" "false" || { printf "  skipped\n"; return 0; }
        [ -e "$backup" ] && die "$backup already exists — refusing to overwrite it"
        sudo mv "$target" "$backup"
    else
        printf "\nOne-time setup (runs with sudo): symlink this checkout to /etc/nixos.\n"
        ask_yes_no "Do it now?" "false" || { printf "  skipped\n"; return 0; }
    fi
    sudo ln -s "$REPO" "$target"
    ok "/etc/nixos -> $REPO"
}

print_git_hint() {
    printf "\n%b\n" "When you are happy with the result, commit it yourself:
  ${CBL}git add hosts/$1${CNC}
  ${CBL}git commit -m \"feat(hosts): add $1 (hamra-init)\"${CNC}"
}

cmd_check() {
    printf "hamra-init --check (read-only audit)\n"
    check_disk
    printf "  repo: %s\n" "$REPO"
    printf "  hosts: %s\n" "$(scanned_hosts | tr '\n' ' ')"
    dummy=$(mktemp)
    printf '{"hostname":"hamra-init-check","username":"check","gpu":"intel","firmware":"uefi","desktop":"hyprland","nas":false,"vnc":false}' > "$dummy"
    json=$(run_renderer "$dummy") || { rm -f "$dummy"; die "could not read toggle universes"; }
    rm -f "$dummy"
    counts=$(jq -r '.counts | "core: \(.core) + optionals: \(.optionals) + home: \(.home)"' <<<"$json")
    total=$(jq -r '[.counts[]] | add' <<<"$json")
    ok "toggle universes reachable: $total toggles ($counts)"
    jq -r '.skipped[] | "warn: ignoring non-toggle option: \(.)"' <<<"$json" >&2 || true
    if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
        ok "sops editing key present"
    else
        warn "no sops editing key (only needed to create/reset NAS passwords)"
    fi
    if grep -q "nix-command" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
        ok "flakes enabled for the user"
    else
        warn "user nix.conf lacks flakes (the wizard enables it; harmless when the system already provides them)"
    fi
    if [ -L /etc/nixos ] && [ "$(readlink -f /etc/nixos)" = "$(readlink -f "$REPO")" ]; then
        ok "/etc/nixos symlinks to this checkout"
    elif [ -L /etc/nixos ]; then
        warn "/etc/nixos symlinks to $(readlink -f /etc/nixos) (not this checkout)"
    elif [ -e /etc/nixos ]; then
        warn "/etc/nixos is the installer's copy (the wizard offers the backup + symlink)"
    else
        warn "/etc/nixos does not exist (the wizard can create the symlink)"
    fi
    printf "\nEnvironment ready for hamra-init.\n"
}

main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --answers) ANSWERS="${2:?--answers needs a file}"; shift 2 ;;
            --dry-run) DRY_RUN=1; shift ;;
            --render-only) RENDER_ONLY=1; shift ;;
            --render-into) RENDER_INTO="${2:?--render-into needs a directory}"; shift 2 ;;
            --check) CHECK=1; shift ;;
            --gates-only) GATES_ONLY="${2:?--gates-only needs a host name}"; shift 2 ;;
            --enable) EXTRA_ENABLE="${2:?--enable needs a comma list}"; shift 2 ;;
            --disable) EXTRA_DISABLE="${2:?--disable needs a comma list}"; shift 2 ;;
            -h|--help) sed -n '3,30p' "$0" | sed 's/^#  \{0,1\}//'; exit 0 ;;
            *) die "unknown argument '$1' (see --help)" ;;
        esac
    done

    [ -f "$REPO/flake.nix" ] \
        || die "repository not found" \
            "Run from the Hamra checkout (or set HAMRA_REPO). Expected flake.nix here:
  $REPO"

    if [ -n "$ANSWERS" ]; then
        [ -f "$ANSWERS" ] || die "answers file not found: $ANSWERS"
        ANSWERS=$(readlink -f "$ANSWERS")
    fi
    [ -n "$RENDER_INTO" ] && RENDER_INTO=$(readlink -m "$RENDER_INTO")

    [ "$CHECK" = "1" ] && { cmd_check; return 0; }

    if [ -n "$GATES_ONLY" ]; then
        [ -d "$REPO/hosts/$GATES_ONLY" ] || die "hosts/$GATES_ONLY does not exist"
        run_gates "$GATES_ONLY" 1
        return 0
    fi

    [ "$RENDER_ONLY" = "0" ] && [ "$DRY_RUN" = "0" ] && [ -z "$RENDER_INTO" ] && ensure_flakes_user

    if [ -n "$ANSWERS" ]; then
        [ -f "$ANSWERS" ] || die "answers file not found: $ANSWERS"
        if [ -n "$EXTRA_ENABLE" ]; then
            items=$(printf "%s" "$EXTRA_ENABLE" | tr ',' '\n' | jq -R . | jq -s .)
            jq --argjson _ "$items" '.enable = ((.enable // []) + $_)' "$ANSWERS" > "$ANSWERS.tmp" && mv "$ANSWERS.tmp" "$ANSWERS"
        fi
        if [ -n "$EXTRA_DISABLE" ]; then
            items=$(printf "%s" "$EXTRA_DISABLE" | tr ',' '\n' | jq -R . | jq -s .)
            jq --argjson _ "$items" '.disable = ((.disable // []) + $_)' "$ANSWERS" > "$ANSWERS.tmp" && mv "$ANSWERS.tmp" "$ANSWERS"
        fi
    else
        ANSWERS=$(mktemp)
        collect_answers
    fi

    validate_answers "$ANSWERS"
    hostname=$(jq -r .hostname "$ANSWERS")

    json=$(run_renderer "$ANSWERS") \
        || die "nix render failed"

    if [ "$RENDER_ONLY" = "1" ]; then
        print_rendered "$hostname" "$json"
        return 0
    fi

    if [ -n "$RENDER_INTO" ]; then
        write_rendered "$RENDER_INTO" "$json"
        return 0
    fi

    jq -r '.autoNotes[] | "  info: auto-adjusted: \(.)"' <<<"$json"
    hardware=$(hardware_config_source) \
        || die "could not produce a hardware-configuration.nix"

    if [ "$DRY_RUN" = "1" ]; then
        print_rendered "$hostname" "$json"
        printf "\n===== hosts/%s/hardware-configuration.nix =====\n" "$hostname"
        printf "%s" "$hardware"
        printf "\n\n(dry-run: nothing was written, gates not run)\n"
        return 0
    fi

    offer_etc_nixos_symlink
    check_dirty_targets "$hostname"
    check_disk
    check_user "$(jq -r .username "$ANSWERS")"
    [ "$(jq -r .nas "$ANSWERS")" = "true" ] && sops_gate

    write_host "$hostname" "$json" "$hardware"
    run_gates "$hostname" 1
    print_git_hint "$hostname"
}

main "$@"
