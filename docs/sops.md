# SOPS Secrets Management

## Overview

Hamra uses **sops-nix** with **age** encryption for secret management. Secrets live in `secrets/*.yaml` (encrypted) and are decrypted automatically at boot/activation to `/run/secrets/`.

---

## Structure

```
secrets/
├── vnc.yaml          # wayvnc password (VNC)
├── samba.yaml        # Samba NAS password
├── wayvnc-tls.yaml   # wayvnc static TLS private key
└── wayvnc-rsa.yaml   # wayvnc static RSA private key

.sops.yaml            # Key/recipient configuration
```

> **Certificates:** The wayvnc TLS *certificate* (public) lives in the repo at `modules/nixos/programs/optionals/services/wayvnc-cert.pem`. Only the *private key* is encrypted in `secrets/wayvnc-tls.yaml`. The RSA key (`secrets/wayvnc-rsa.yaml`) is what clients see as a fingerprint; see [`vnc.md`](vnc.md).

---

## Keys (Age)

| Type | Location | Purpose |
|------|----------|---------|
| **Editing key** (private) | `~/.config/sops/age/keys.txt` | **Single machine only** — used to edit/create secrets (`sops secrets/...`, `sops updatekeys`) |
| **Host keys** (public) | `.sops.yaml` (in repo) | Each host that needs to decrypt — derived from the host's SSH key |

### Generate host key
```bash
# Run ON EACH HOST (acer, samsung, vm, etc.)
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
# Output: age1abc... → add to .sops.yaml
```

### Editing key (generate once)
```bash
age-keygen > ~/.config/sops/age/keys.txt
# Store securely — this key can decrypt EVERYTHING
```

---

## Current .sops.yaml

```yaml
keys:
  # Editing key (machine that runs `sops updatekeys` / `sops edit`)
  - &user age1sq570spnk7jm72zzyqa9h264pxulx0xqu8m2hj0ka3u27ca3uycsk3xfhu

  # Host keys (public — derived from each machine's SSH host key)
  - &host-samsung age1jke3vagr84utrxqsd89m3vpxmr9wgcr44tycngm4lf0570h4tsdqvr23yf
  - &host-acer    age1uw4uek9vywsw0x23hrx65pcdgqp4tmaf8pcfal54k2zct79azecq4s5qm5
  # - &host-vm age1...

creation_rules:
  # vnc.yaml: wayvnc server may run on any host that enables it
  - path_regex: secrets/vnc\.yaml$
    key_groups:
      - age:
          - *user
          - *host-samsung
          - *host-acer

  # wayvnc-tls.yaml: static TLS private key for wayvnc (same hosts as vnc.yaml)
  - path_regex: secrets/wayvnc-tls\.yaml$
    key_groups:
      - age:
          - *user
          - *host-samsung
          - *host-acer

  # wayvnc-rsa.yaml: static RSA private key for wayvnc auth (same hosts as vnc.yaml)
  - path_regex: secrets/wayvnc-rsa\.yaml$
    key_groups:
      - age:
          - *user
          - *host-samsung
          - *host-acer

  # samba.yaml: Samba server runs on the NAS host; clients may need it for activation scripts
  - path_regex: secrets/samba\.yaml$
    key_groups:
      - age:
          - *user
          - *host-samsung
          - *host-acer
```

### Current Rules
| Secret | Hosts that can decrypt | Rationale |
|--------|------------------------|-----------|
| `vnc.yaml` | samsung, acer | wayvnc server can be enabled on any host via toggle |
| `wayvnc-tls.yaml` | samsung, acer | static TLS key for wayvnc (same hosts as vnc.yaml) |
| `wayvnc-rsa.yaml` | samsung, acer | static RSA key for wayvnc RA2 auth (same hosts as vnc.yaml) |
| `samba.yaml` | acer (NAS), samsung (client) | NAS host runs the server; client hosts run activation scripts that read the password |

> **Note:** Roles are not fixed. Any host can become a wayvnc server or Samba NAS by enabling the corresponding toggle. The recipient list simply includes all hosts that *might* need the secret.

---

## wayvnc Static TLS Certificate (No More Regeneration)

### Problem with the old approach
The original wayvnc module generated a **new self-signed certificate + RSA key on every boot** (`~/.local/state/wayvnc/`). This caused:
- Remmina (and other VNC clients) to prompt "untrusted certificate" **every connection**
- No way to "trust once" because the cert changed each reboot
- 300+ lines of shell script for cert/key management

### Solution: Static cert/key via SOPS
1. **Certificate (public)** → committed to repo: `modules/nixos/programs/optionals/services/wayvnc-cert.pem`
2. **Private key (secret)** → encrypted in SOPS: `secrets/wayvnc-tls.yaml`
3. **Generation: once** (100-year validity = 36500 days)
4. **Result:** Remmina prompts **once**, you click "Always trust", done forever.

### Generate the cert/key pair (run once, on any machine with openssl)
```bash
# 100-year validity (36500 days), RSA 4096
openssl req -x509 -newkey rsa:4096 -sha256 -days 36500 -nodes \
  -keyout wayvnc-key.pem -out wayvnc-cert.pem \
  -subj "/CN=wayvnc" -addext "subjectAltName=IP:127.0.0.1,IP:::1"

# wayvnc-cert.pem → commit to repo (modules/nixos/programs/optionals/services/)
# wayvnc-key.pem  → put in sops (see below)
```

### Add private key to SOPS (on editing-key machine)
```bash
# Create the sops file with the private key
nix develop --command sops secrets/wayvnc-tls.yaml
# Paste content:
# wayvnc_tls_key: |
#   -----BEGIN PRIVATE KEY-----
#   ...
#   -----END PRIVATE KEY-----
# Save → encrypts for all recipients in .sops.yaml

git add secrets/wayvnc-tls.yaml .sops.yaml
git commit -m "chore(sops): add wayvnc static TLS key"
git push
```

### Update recipients when adding a new host
```bash
# On editing-key machine (after adding host key to .sops.yaml)
sops updatekeys secrets/wayvnc-tls.yaml secrets/wayvnc-rsa.yaml secrets/vnc.yaml secrets/samba.yaml
git add secrets/*.yaml .sops.yaml
git commit -m "chore(sops): sync recipients for new host"
git push
```

### What the module does with them
- No runtime cert/RSA generation: the files come from the repo + sops.
- At start the unit writes `$XDG_RUNTIME_DIR/wayvnc.conf` (mode 0600) with
  `enable_auth=true`, `username`, `password` (read from `/run/secrets/vnc-password`),
  `certificate_file`, `private_key_file` and `rsa_private_key_file`, then execs
  `wayvnc --config`.
- Key formats matter: TLS key is PKCS#8 (GnuTLS), RSA key is PKCS#1 (nettle).
- Client-facing details (which security types work, client recipe) live in
  [`vnc.md`](vnc.md).

### Machine lifecycle considerations

| Scenario | What happens | Action needed |
|----------|--------------|---------------|
| **Host rebuild** (same machine) | Same cert/key used, no change | Nothing |
| **OS reinstall** (new SSH host key) | New host key → add to `.sops.yaml` → `sops updatekeys` → rebuild | Run `sops updatekeys` on editing machine |
| **New machine** | Generate host key → add to `.sops.yaml` → `sops updatekeys` → rebuild | Same as above |
| **Cert compromised** | `./scripts/setup-vnc.sh --rotate-certs` (regenerates cert + TLS key + RSA key, commits, pushes) → `sops updatekeys` if recipients changed → rebuild all hosts | Run on editing machine |
| **Cert expired** (36500 days ≈ 100 years) | Practically never, but same as "compromised" | Same as above |

> **Key insight:** The cert/key are **not tied to the machine identity**. They're just a static TLS identity for the wayvnc service. The *machine identity* is handled by the host SSH key (for sops decryption). This means:
> - You can move the cert/key to a new machine without regenerating
> - Only the sops recipients need updating when machines change
> - The 100-year validity means "effectively never expires"

---

## Common Workflows

### 1. Edit a secret (e.g., change VNC password)
```bash
# On the machine WITH the editing key (~/.config/sops/age/keys.txt)
sops secrets/vnc.yaml
# Opens $EDITOR with decrypted YAML
# Save → auto-reencrypts for ALL recipients in .sops.yaml
git add secrets/vnc.yaml && git commit -m "chore: update vnc password" && git push
```

### 2. Add a new host (e.g., vm)
```bash
# 1. On the new host: generate host key
ssh vm "cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age"
# → age1vm...

# 2. In repo: add to .sops.yaml
#    keys: - &host-vm age1vm...
#    creation_rules: add *host-vm to secrets the vm needs

# 3. On editing-key machine:
nix develop --command sops updatekeys secrets/vnc.yaml secrets/samba.yaml secrets/wayvnc-tls.yaml
git add .sops.yaml secrets/*.yaml && git commit -m "chore(sops): add vm key" && git push

# 4. On vm: pull + rebuild
```

### 3. Rotate editing key (if compromised)
```bash
# 1. Generate new
age-keygen > ~/.config/sops/age/keys.txt.new
# 2. Update .sops.yaml (replace &user)
# 3. Re-encrypt all:
nix develop --command sops updatekeys secrets/*.yaml
git add .sops.yaml secrets/*.yaml && git commit -m "chore(sops): rotate editing key" && git push
```

### 4. View secret without editing
```bash
# On any host that can decrypt (has its host key in .sops.yaml)
nix develop --command sops -d secrets/vnc.yaml
```

---

## How It Works at Boot (sops-nix)

1. `configuration.nix` imports the `sops-nix` module
2. `sops.secrets.<name>` defines:
   - `sopsFile` = `secrets/...yaml`
   - `owner` / `mode` / `group`
3. During **activation** (before switch):
   - sops-nix decrypts using the **host's private SSH key** (`/etc/ssh/ssh_host_ed25519_key`)
   - Writes to `/run/secrets/<name>` (e.g., `/run/secrets/vnc-password`, `/run/secrets/wayvnc-tls-key`)
4. Services read from `/run/secrets/...`

### Example (wayvnc):
```nix
sops.secrets."vnc-password" = {
  sopsFile = "${config.hamra.secrets.path}/vnc.yaml";
  owner = config.hamra.users.userName;
  mode = "0400";
};

sops.secrets."wayvnc-tls-key" = {
  sopsFile = "${config.hamra.secrets.path}/wayvnc-tls.yaml";
  owner = config.hamra.users.userName;
  mode = "0400";
};

# wayvnc command uses:
# --cert-file=/path/to/wayvnc-cert.pem
# --key-file=/run/secrets/wayvnc-tls-key
# --config=/run/user/.../wayvnc.conf (contains password from /run/secrets/vnc-password)
```

---

## Machine State

| Machine | Has editing key? | Host key in .sops.yaml? | Decrypts vnc.yaml? | Decrypts wayvnc-tls.yaml? | Decrypts samba.yaml? |
|---------|------------------|-------------------------|--------------------|---------------------------|----------------------|
| **samsung** | ❌ (likely not) | ✅ `host-samsung` | ✅ | ✅ | ✅ |
| **acer** | ❌ | ✅ `host-acer` | ✅ | ✅ | ✅ |
| **vm** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Editing machine** | ✅ | — | — | — | — |

> **Important:** Only **one** machine holds the private editing key (`~/.config/sops/age/keys.txt`). Other machines use their host key (derived from SSH) for boot-time decryption.

---

## Troubleshooting

### "FAILED to decrypt / No master key"
- Running `sops` on a machine **without the editing key** AND **without a valid host key in .sops.yaml**
- Fix: run on the editing-key machine, or add this machine's host key to .sops.yaml + run `sops updatekeys`

### "identity did not match any recipients"
- File was encrypted for recipients that **don't include** this machine's key
- Fix: `sops updatekeys` on the editing-key machine

### New host fails to decrypt at boot
- Verify host public key is in `.sops.yaml` AND in the relevant `creation_rules`
- Verify `sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"]` is in the module
- Rebuild: `sudo nixos-rebuild switch --flake .#host`

### Host SSH key changed (OS reinstall)
```bash
# 1. New host key
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
# 2. Update .sops.yaml
# 3. sops updatekeys (on editing-key machine)
# 4. Rebuild on host
```

### wayvnc: Remmina still shows certificate warning after rebuild
- Verify `wayvnc-cert.pem` is in the module directory and committed
- Verify `wayvnc-tls.yaml` decrypts on the host: `nix develop --command sops -d secrets/wayvnc-tls.yaml`
- Check wayvnc logs: `journalctl --user -u wayvnc -f`
- Ensure the cert's SAN includes the IPs you connect from (127.0.0.1, ::1 by default)

---

## Useful Commands

```bash
# View recipients of a file
sops -i secrets/vnc.yaml   # opens editor
sops -d secrets/vnc.yaml   # decrypts to stdout

# Update recipients (on editing-key machine)
sops updatekeys secrets/vnc.yaml secrets/samba.yaml secrets/wayvnc-tls.yaml

# Verify local decryption works
nix develop --command sops -d secrets/vnc.yaml

# Generate host age key from SSH key
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age

# Generate editing key (once)
age-keygen > ~/.config/sops/age/keys.txt

# Generate wayvnc static cert/key (once, 100-year validity)
openssl req -x509 -newkey rsa:4096 -sha256 -days 36500 -nodes \
  -keyout wayvnc-key.pem -out wayvnc-cert.pem \
  -subj "/CN=wayvnc" -addext "subjectAltName=IP:127.0.0.1,IP:::1"
```

---

## Security

- **NEVER** commit private keys (age or SSH)
- `secrets/*.yaml` are **encrypted** — safe to commit
- `.sops.yaml` contains only **public keys** — safe to commit
- Editing private key (`~/.config/sops/age/keys.txt`) **stays out of repo** — back up securely (password manager, offline USB, etc.)
- Host private keys live in `/etc/ssh/` (protected by the OS)
- wayvnc TLS private key (`wayvnc-tls.yaml`) is encrypted in sops; only the certificate is public