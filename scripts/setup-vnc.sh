#!/usr/bin/env bash
# setup-vnc - Configure wayvnc with static TLS cert/key and VNC password via SOPS
# Usage: setup-vnc [--check] [--rotate-password] [--rotate-certs] [--help]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[setup-vnc]${NC} $*"; }
warn() { echo -e "${YELLOW}[setup-vnc]${NC} $*"; }
error() { echo -e "${RED}[setup-vnc]${NC} $*" >&2; }
ok() { echo -e "${GREEN}[setup-vnc]${NC} $*"; }

show_help() {
    cat <<'HELP'
setup-vnc - Configure wayvnc static credentials via SOPS

USAGE:
    setup-vnc [OPTIONS]

OPTIONS:
    --check              Verify current configuration (decrypt all secrets)
    --rotate-password    Generate new VNC password and update SOPS
    --rotate-certs       Generate new TLS cert/key + RSA key and update SOPS
    --rotate-all         Rotate password, TLS cert/key, and RSA key
    --help               Show this help

EXAMPLES:
    setup-vnc --check              # Verify everything decrypts
    setup-vnc --rotate-password    # New VNC password only
    setup-vnc --rotate-all         # Full rotation (password + certs + keys)

NOTES:
    - Must run on machine with SOPS editing key (~/.config/sops/age/keys.txt)
    - SSH host keys only work with sops-nix during system activation (not manual sops)
    - After rotation, run 'nixos-rebuild switch' on samsung and acer
    - Certificate is 100-year self-signed (36500 days)
    - RSA key is PKCS#1 format (-----BEGIN RSA PRIVATE KEY-----) for nettle compatibility

FILES MANAGED:
    secrets/vnc.yaml           # VNC password (vnc-password)
    secrets/wayvnc-tls.yaml    # TLS private key (wayvnc-tls-key)
    secrets/wayvnc-rsa.yaml    # RSA private key (wayvnc-rsa-key)
    modules/nixos/programs/optionals/services/wayvnc-cert.pem  # TLS cert (public, in repo)
    .sops.yaml                 # Recipient rules (updated if needed)

RECIPIENTS (from .sops.yaml):
    - Editing key (age1sq570spnk...)
    - samsung (age1jke3vagr...)
    - acer (age1uw4uek9v...)
HELP
}

check_sops_key() {
    if [[ -f ~/.config/sops/age/keys.txt ]]; then
        ok "Found editing key at ~/.config/sops/age/keys.txt"
        return 0
    fi
    error "No SOPS editing key found at ~/.config/sops/age/keys.txt"
    error "Manual sops operations require the editing key."
    error "SSH host keys only work with sops-nix during system activation."
    return 1
}

decrypt_secret() {
    local file="$1"
    local key_var="$2"
    
    if [[ -f ~/.config/sops/age/keys.txt ]]; then
        SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt nix develop --command sops -d "$file" 2>/dev/null | grep -oP '(?<='"$key_var"': ).*' | tr -d '"'
    else
        error "SSH host key decryption not supported for manual sops commands."
        error "Use the editing key (~/.config/sops/age/keys.txt) or run via sops-nix at activation."
        return 1
    fi
}

cmd_check() {
    log "Checking SOPS decryption for all wayvnc secrets..."
    check_sops_key || return 1
    
    log "Checking vnc.yaml (vnc-password)..."
    if decrypt_secret secrets/vnc.yaml "vnc-password" >/dev/null; then
        ok "vnc.yaml decrypts OK"
    else
        error "vnc.yaml FAILED to decrypt"
        return 1
    fi
    
    log "Checking wayvnc-tls.yaml (wayvnc-tls-key)..."
    if decrypt_secret secrets/wayvnc-tls.yaml "wayvnc-tls-key" >/dev/null; then
        ok "wayvnc-tls.yaml decrypts OK"
    else
        error "wayvnc-tls.yaml FAILED to decrypt"
        return 1
    fi
    
    log "Checking wayvnc-rsa.yaml (wayvnc-rsa-key)..."
    local rsa_decrypt
    rsa_decrypt=$(decrypt_secret secrets/wayvnc-rsa.yaml "wayvnc-rsa-key" "wayvnc-rsa-key")
    if [[ -n "$rsa_decrypt" ]]; then
        ok "wayvnc-rsa.yaml decrypts OK"
    else
        error "wayvnc-rsa.yaml FAILED to decrypt"
        return 1
    fi
    
    log "Checking cert/key match..."
    local cert_mod
    cert_mod=$(openssl x509 -noout -modulus -in modules/nixos/programs/optionals/services/wayvnc-cert.pem 2>/dev/null | openssl md5 | awk '{print $2}')
    local key_mod
    key_mod=$(decrypt_secret secrets/wayvnc-tls.yaml "wayvnc-tls-key" "wayvnc-tls-key" | openssl rsa -noout -modulus 2>/dev/null | openssl md5 | awk '{print $2}')
    if [[ "$cert_mod" == "$key_mod" && -n "$cert_mod" ]]; then
        ok "Cert/key modulus match: $cert_mod"
    else
        error "Cert/key modulus MISMATCH (cert: $cert_mod, key: $key_mod)"
        return 1
    fi
    
    ok "All checks passed!"
}

rotate_password() {
    log "Rotating VNC password..."
    check_sops_key || return 1
    
    local new_pass
    new_pass=$(openssl rand -base64 16)
    log "Generated new password: $new_pass"
    
    cat > secrets/vnc.yaml <<YAML
vnc-password: "$new_pass"
YAML
    
    nix develop --command sops --encrypt --in-place secrets/vnc.yaml
    ok "secrets/vnc.yaml updated"
    
    git add secrets/vnc.yaml
    git commit -m "chore(vnc): rotate VNC password"
    git push origin main
    ok "Pushed to origin/main"
    
    warn "Run rebuild on samsung and acer:"
    warn "  sudo nixos-rebuild switch --flake .#samsung"
    warn "  sudo nixos-rebuild switch --flake .#acer"
}

rotate_certs() {
    log "Rotating TLS cert/key pair and RSA key..."
    check_sops_key || return 1
    
    # Generate new TLS cert + PKCS#8 key (GnuTLS accepts PKCS#8)
    log "Generating new self-signed cert (100 years) + TLS key..."
    openssl req -x509 -newkey rsa:4096 -sha256 -days 36500 -nodes \
        -keyout /tmp/wayvnc-tls-key.pem -out /tmp/wayvnc-cert.pem \
        -subj "/CN=wayvnc" -addext "subjectAltName=IP:127.0.0.1,IP:::1"
    
    # Verify match
    local cert_mod
    cert_mod=$(openssl x509 -noout -modulus -in /tmp/wayvnc-cert.pem | openssl md5 | awk '{print $2}')
    local key_mod
    key_mod=$(openssl rsa -noout -modulus -in /tmp/wayvnc-tls-key.pem | openssl md5 | awk '{print $2}')
    if [[ "$cert_mod" != "$key_mod" ]]; then
        error "Cert/key generation failed - modulus mismatch"
        return 1
    fi
    ok "Cert/key match: $cert_mod"
    
    # Copy cert to repo (public)
    cp /tmp/wayvnc-cert.pem modules/nixos/programs/optionals/services/wayvnc-cert.pem
    ok "Cert updated in repo"
    
    # Encrypt TLS key
    log "Encrypting TLS private key..."
    local tls_key
    tls_key=$(cat /tmp/wayvnc-tls-key.pem)
    cat > secrets/wayvnc-tls.yaml <<YAML
wayvnc-tls-key: |
$(echo "$tls_key" | sed 's/^/  /')
YAML
    nix develop --command sops --encrypt --in-place secrets/wayvnc-tls.yaml
    ok "secrets/wayvnc-tls.yaml updated"
    
    # Generate RSA key in PKCS#1 format (for nettle)
    log "Generating RSA key (PKCS#1 format for nettle)..."
    openssl genrsa -traditional -out /tmp/wayvnc-rsa-key.pem 4096
    local rsa_first
    rsa_first=$(head -1 /tmp/wayvnc-rsa-key.pem)
    if [[ "$rsa_first" != "-----BEGIN RSA PRIVATE KEY-----" ]]; then
        error "RSA key not in PKCS#1 format: $rsa_first"
        return 1
    fi
    ok "RSA key format: PKCS#1"
    
    # Encrypt RSA key
    log "Encrypting RSA private key..."
    local rsa_key
    rsa_key=$(cat /tmp/wayvnc-rsa-key.pem)
    cat > secrets/wayvnc-rsa.yaml <<YAML
wayvnc-rsa-key: |
$(echo "$rsa_key" | sed 's/^/  /')
YAML
    nix develop --command sops --encrypt --in-place secrets/wayvnc-rsa.yaml
    ok "secrets/wayvnc-rsa.yaml updated"
    
    # Commit all
    git add modules/nixos/programs/optionals/services/wayvnc-cert.pem secrets/wayvnc-tls.yaml secrets/wayvnc-rsa.yaml
    git commit -m "chore(vnc): rotate TLS cert/key and RSA key"
    git push origin main
    ok "Pushed to origin/main"
    
    warn "Run rebuild on samsung and acer:"
    warn "  sudo nixos-rebuild switch --flake .#samsung"
    warn "  sudo nixos-rebuild switch --flake .#acer"
}

rotate_all() {
    rotate_password
    rotate_certs
}

# Main
case "${1:-}" in
    --check)
        cmd_check
        ;;
    --rotate-password)
        rotate_password
        ;;
    --rotate-certs)
        rotate_certs
        ;;
    --rotate-all)
        rotate_all
        ;;
    --help|-h|"")
        show_help
        ;;
    *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac
