# Security Policy

## Reporting a vulnerability

Use the **Report a vulnerability** button in the repository's Security tab
(GitHub's Private Vulnerability Reporting) instead of opening a public
issue. Describe the problem, how to reproduce it, and the impact. This is a
personal project maintained by one person — no formal SLA, but reports get
a response as soon as possible.

**In scope for reporting here:**

- Exposure of secrets or credentials (accidental commit, configuration
  that leaks a value in plaintext).
- Insecure configuration of this repository's modules (permissions, polkit,
  sudo, PAM, SSH).
- Privilege escalation induced by something declared here.

**Out of scope:** vulnerabilities in packaged programs (Hyprland, Noctalia,
mise etc.) — report those upstream in each project.

## How this repository handles secrets

- Secrets live **encrypted** in `secrets/*.yaml` (sops-nix + age).
  Plaintext values never enter the repository.
- Public keys per host live in `.sops.yaml`; the private editing key lives
  in `~/.config/sops/age/keys.txt` on the editor's machine — outside the
  repo, outside the Nix Store.
- Each host decrypts with the key derived from its own
  `ssh_host_ed25519_key` (registered via `ssh-to-age`). A new host must
  have its key registered and the secret updated (`sops updatekeys`) —
  without that it cannot open the content.
- Service passwords (e.g. Samba) are applied on activation from the
  decrypted secrets — nothing passes through the Nix Store.
- Polkit, keyring, GnuPG, and SSH are `core` modules with explicit toggles.

## Honest limitations

- The Samba shares' trash bin (VFS recycle) is a buffer against accidents
  over the SMB client, not a backup. It does not protect against a direct
  `rm` on the server.
- The hosts in this repo belong to the author's machines; hardware and
  identity live in `hosts/<name>/` and the rest is reusable by any fork.
