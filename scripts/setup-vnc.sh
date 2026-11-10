#!/usr/bin/env bash
#
# setup-vnc — Manage the wayvnc credentials (password + static TLS/RSA keys)
# stored with sops in this repository.
#
# Modes:
#   ./scripts/setup-vnc.sh --check            verify the secrets and the keys
#   ./scripts/setup-vnc.sh --show-password    print the current VNC password
#   ./scripts/setup-vnc.sh --rotate-password  generate a new VNC password
#   ./scripts/setup-vnc.sh --rotate-certs     generate new TLS cert/key + RSA key
#   ./scripts/setup-vnc.sh --rotate-all       password + certs
#   ./scripts/setup-vnc.sh --help             this help
#
# Needs the sops editing key at ~/.config/sops/age/keys.txt and must run on the
# machine that holds it. After any rotation, rebuild every host with the
# wayvnc toggle: sudo nixos-rebuild switch --flake .#<host>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

CERT_FILE="modules/nixos/programs/optionals/services/wayvnc-cert.pem"
PW_SECRET="secrets/vnc.yaml"
TLS_SECRET="secrets/wayvnc-tls.yaml"
RSA_SECRET="secrets/wayvnc-rsa.yaml"
AGE_KEY="$HOME/.config/sops/age/keys.txt"

TMPDIR_SETUP=""
cleanup() {
  if [[ -n "$TMPDIR_SETUP" && -d "$TMPDIR_SETUP" ]]; then
    shopt -u nullglob
    rm -rf "$TMPDIR_SETUP"
  fi
}
trap cleanup EXIT INT TERM

if [[ -t 1 ]]; then
  _R=$'\033[31m'; _G=$'\033[32m'; _Y=$'\033[33m'; _C=$'\033[36m'; _N=$'\033[0m'
else
  _R=""; _G=""; _Y=""; _C=""; _N=""
fi

info() { printf "%s[setup-vnc]%s %s\n" "$_C" "$_N" "$*"; }
ok() { printf "%s[setup-vnc]%s %s\n" "$_G" "$_N" "$*"; }
warn() { printf "%s[setup-vnc]%s %s\n" "$_Y" "$_N" "$*"; }
die() {
  printf "%s[setup-vnc]%s %s\n" "$_R" "$_N" "$*" >&2
  exit 1
}

show_help() {
  sed -n '3,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  cat <<'HELP'

FILES MANAGED
  secrets/vnc.yaml                                       vnc-password
  secrets/wayvnc-tls.yaml                                wayvnc-tls-key
  secrets/wayvnc-rsa.yaml                                wayvnc-rsa-key
  modules/nixos/programs/optionals/services/wayvnc-cert.pem   public TLS cert

KEY FORMATS (they matter to the server)
  wayvnc-tls-key   PKCS#8  ("BEGIN PRIVATE KEY"), GnuTLS
  wayvnc-rsa-key   PKCS#1  ("BEGIN RSA PRIVATE KEY"), nettle
  the cert and the TLS key must be a matching pair (same modulus)

CLIENTS
  The server accepts RA2/RA2_256 (RSA-AES, user + password) and X509Plain
  (TLS + user + password). See docs/vnc.md for the client recipe.
HELP
}

tool() {
  local bin=$1
  shift
  if command -v "$bin" >/dev/null 2>&1; then
    "$bin" "$@"
  else
    nix run "nixpkgs#$bin" -- "$@"
  fi
}

sops_() {
  SOPS_AGE_KEY_FILE="$AGE_KEY" tool sops "$@"
}

openssl_() {
  tool openssl "$@"
}

need_key() {
  [[ -f "$AGE_KEY" ]] || die "editing key not found at $AGE_KEY (run this on the machine that owns it)"
}

need_repo() {
  [[ -f "$PW_SECRET" && -f "$TLS_SECRET" && -f "$RSA_SECRET" ]] \
    || die "missing secret files (expected $PW_SECRET, $TLS_SECRET, $RSA_SECRET)"
}

decrypt_field() {
  local file=$1 key=$2
  sops_ -d --extract "[\"$key\"]" "$file"
}

encrypt_in_place() {
  local file=$1
  sops_ --encrypt --in-place "$file"
  ok "$file encrypted"
}

new_tmp() {
  if [[ -z "$TMPDIR_SETUP" ]]; then
    TMPDIR_SETUP=$(mktemp -d)
    chmod 700 "$TMPDIR_SETUP"
  fi
  echo "$TMPDIR_SETUP"
}

cmd_check() {
  need_key
  need_repo

  local dir
  dir=$(new_tmp)

  info "decrypting vnc-password"
  local pw
  pw=$(decrypt_field "$PW_SECRET" vnc-password) || die "vnc.yaml does not decrypt"
  [[ -n "$pw" ]] || die "vnc-password is empty"
  ok "vnc-password decrypts (${#pw} chars)"

  info "decrypting wayvnc-tls-key"
  decrypt_field "$TLS_SECRET" wayvnc-tls-key >"$dir/tls.pem" || die "wayvnc-tls.yaml does not decrypt"
  grep -q "BEGIN" "$dir/tls.pem" || die "wayvnc-tls-key is not a PEM block"
  ok "wayvnc-tls-key decrypts ($(head -1 "$dir/tls.pem" | tr -d '-'))"

  info "decrypting wayvnc-rsa-key"
  decrypt_field "$RSA_SECRET" wayvnc-rsa-key >"$dir/rsa.pem" || die "wayvnc-rsa.yaml does not decrypt"
  head -1 "$dir/rsa.pem" | grep -qx -- "-----BEGIN RSA PRIVATE KEY-----" \
    || die "wayvnc-rsa-key is not PKCS#1 (nettle rejects PKCS#8): $(head -1 "$dir/rsa.pem")"
  openssl_ rsa -in "$dir/rsa.pem" -check -noout >/dev/null 2>&1 || die "wayvnc-rsa-key is not a valid RSA key"
  ok "wayvnc-rsa-key decrypts and is valid PKCS#1"

  info "comparing cert and TLS key moduli"
  local cert_mod key_mod
  cert_mod=$(openssl_ x509 -noout -modulus -in "$CERT_FILE" | openssl_ md5)
  key_mod=$(openssl_ rsa -noout -modulus -in "$dir/tls.pem" | openssl_ md5)
  [[ "$cert_mod" == "$key_mod" ]] || die "cert/key modulus mismatch (cert: $cert_mod, key: $key_mod)"
  ok "cert and TLS key match ($cert_mod)"

  ok "all checks passed"
}

cmd_show_password() {
  need_key
  need_repo
  decrypt_field "$PW_SECRET" vnc-password
  echo
}

git_commit_push() {
  local msg=$1
  shift
  git add "$@"
  git commit -m "$msg"
  git push origin HEAD
  ok "pushed to origin"
}

cmd_rotate_password() {
  need_key
  need_repo

  local pw
  pw=$(openssl_ rand -base64 16)
  cat >"$PW_SECRET" <<YAML
vnc-password: "$pw"
YAML

  encrypt_in_place "$PW_SECRET"
  git_commit_push "chore(vnc): rotate VNC password" "$PW_SECRET"

  echo
  warn "new VNC password: $pw"
  warn "rebuild the host that runs wayvnc: sudo nixos-rebuild switch --flake .#<host>"
}

cmd_rotate_certs() {
  need_key
  need_repo

  local dir
  dir=$(new_tmp)

  info "generating TLS cert/key pair (100 years)"
  openssl_ req -x509 -newkey rsa:4096 -sha256 -days 36500 -nodes \
    -keyout "$dir/tls.pem" -out "$dir/cert.pem" \
    -subj "/CN=wayvnc" -addext "subjectAltName=IP:127.0.0.1,IP:::1" >/dev/null 2>&1 \
    || die "openssl failed to generate the TLS pair"

  local cert_mod key_mod
  cert_mod=$(openssl_ x509 -noout -modulus -in "$dir/cert.pem" | openssl_ md5)
  key_mod=$(openssl_ rsa -noout -modulus -in "$dir/tls.pem" | openssl_ md5)
  [[ "$cert_mod" == "$key_mod" ]] || die "generated cert/key do not match"
  ok "cert/key match ($cert_mod)"

  info "generating RSA key (PKCS#1, nettle)"
  openssl_ genrsa -traditional -out "$dir/rsa.pem" 4096 >/dev/null 2>&1
  head -1 "$dir/rsa.pem" | grep -qx -- "-----BEGIN RSA PRIVATE KEY-----" \
    || die "generated RSA key is not PKCS#1"
  ok "RSA key is PKCS#1"

  cp "$dir/cert.pem" "$CERT_FILE"

  {
    echo "wayvnc-tls-key: |"
    sed 's/^/  /' "$dir/tls.pem"
  } >"$TLS_SECRET"
  encrypt_in_place "$TLS_SECRET"

  {
    echo "wayvnc-rsa-key: |"
    sed 's/^/  /' "$dir/rsa.pem"
  } >"$RSA_SECRET"
  encrypt_in_place "$RSA_SECRET"

  git_commit_push "chore(vnc): rotate TLS cert/key and RSA key" \
    "$CERT_FILE" "$TLS_SECRET" "$RSA_SECRET"

  echo
  warn "clients must accept the new server fingerprint on the next connection"
  warn "rebuild the host that runs wayvnc: sudo nixos-rebuild switch --flake .#<host>"
}

cmd_rotate_all() {
  cmd_rotate_password
  cmd_rotate_certs
}

case "${1:-}" in
  --check) cmd_check ;;
  --show-password) cmd_show_password ;;
  --rotate-password) cmd_rotate_password ;;
  --rotate-certs) cmd_rotate_certs ;;
  --rotate-all) cmd_rotate_all ;;
  --help | -h | "") show_help ;;
  *)
    printf "%s[setup-vnc]%s unknown option: %s\n" "$_R" "$_N" "$1" >&2
    show_help
    exit 1
    ;;
esac
