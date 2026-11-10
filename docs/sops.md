# SOPS Secrets Management

## Overview

Hamra uses **sops-nix** with **age** encryption for secret management. Secrets live in `secrets/*.yaml` (encrypted) and are decrypted automatically at boot/activation to `/run/secrets/`.

---

## Structure

```
secrets/
├── vnc.yaml       # wayvnc password (VNC)
└── samba.yaml     # Samba NAS password

.sops.yaml         # Key/recipient configuration
```

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
| `samba.yaml` | acer (NAS), samsung (client) | NAS host runs the server; client hosts run activation scripts that read the password |

> **Note:** Roles are not fixed. Any host can become a wayvnc server or Samba NAS by enabling the corresponding toggle. The recipient list simply includes all hosts that *might* need the secret.

---

## Common Workflows

### 1. Edit a secret (e.g., change VNC password)
```bash
# On the machine WITH the editing key (~/.config/sops/age/keys.txt)
nix develop --command sops secrets/vnc.yaml
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
nix develop --command sops updatekeys secrets/vnc.yaml secrets/samba.yaml
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
   - Writes to `/run/secrets/<name>` (e.g., `/run/secrets/vnc-password`)
4. Services read from `/run/secrets/...`

### Example (wayvnc):
```nix
sops.secrets."vnc-password" = {
  sopsFile = "${config.hamra.secrets.path}/vnc.yaml";
  owner = config.hamra.users.userName;
  mode = "0400";
};
# systemd service uses: ExecStart = "... --password-file /run/secrets/vnc-password"
```

---

## Machine State

| Machine | Has editing key? | Host key in .sops.yaml? | Decrypts vnc.yaml? | Decrypts samba.yaml? |
|---------|------------------|-------------------------|--------------------|----------------------|
| **samsung** | ❌ (likely not) | ✅ `host-samsung` | ✅ | ✅ |
| **acer** | ❌ | ✅ `host-acer` | ✅ | ✅ |
| **vm** | ❌ | ❌ | ❌ | ❌ |
| **Editing machine** | ✅ | — | — | — |

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

---

## Useful Commands

```bash
# View recipients of a file
sops -i secrets/vnc.yaml   # opens editor
sops -d secrets/vnc.yaml   # decrypts to stdout

# Update recipients (on editing-key machine)
sops updatekeys secrets/vnc.yaml secrets/samba.yaml

# Verify local decryption works
nix develop --command sops -d secrets/vnc.yaml

# Generate host age key from SSH key
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age

# Generate editing key (once)
age-keygen > ~/.config/sops/age/keys.txt
```

---

## Security

- **NEVER** commit private keys (age or SSH)
- `secrets/*.yaml` are **encrypted** — safe to commit
- `.sops.yaml` contains only **public keys** — safe to commit
- Editing private key (`~/.config/sops/age/keys.txt`) **stays out of repo** — back up securely (password manager, offline USB, etc.)
- Host private keys live in `/etc/ssh/` (protected by the OS)