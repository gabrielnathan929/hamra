# Architecture

## Where does the configuration that boots this machine come from?

Short answer: the active system is the closure of the last
`nixos-rebuild switch --flake <checkout>#<host>`. The **Git repository is the
source of truth**; `/etc/nixos` is just an optional symlink pointing to the
checkout — a convenience for `nixos-rebuild` without `--flake` and for the
`setup-nas` assistant, which expect the traditional path. The checkout lives
in the user's home, at any path, and a rebuild done through the symlink
preserves the revision (git detection follows the link).

The full chain:

```
flake.nix + flake.lock (pinned inputs, nixos-26.05)
  -> mkHost (flake/hosts.nix; hosts discovered by scanning hosts/*; specialArgs: self, inputs, hostName, hamraLib)
    -> hosts/<machine>/configuration.nix    (import shim: modules + split host files)
    -> hosts/<machine>/config/{system,hardware,desktop,programs-core,programs-optionals,home}.nix (atomic unit: identity, choices, full toggle menus)
    -> hosts/<machine>/hardware-configuration.nix (physical identity; generated on the machine)
    -> modules/nixos/{core,programs,desktops} (auto-import via hamraLib.scanPaths)
    -> home-manager (extraSpecialArgs: theme, keyboard, desktop, env...)
    -> assertions (desktop, GPU, theme, invalid host role break the eval)
  -> closure -> switch -> /run/current-system
```

The active system's name follows `hamra.networking.hostname`
(e.g. `nixos-system-samsung`), and `system.configurationRevision` records the
build's commit when the rebuild runs from a git checkout (the
`deploy-<host>` app uses a copy of the source in the store and currently
loses this marker — for traceability, prefer
`sudo nixos-rebuild switch --flake .#<host>` from the repo root).

## Hosts: named by machine

There is exactly one host per machine: `samsung`, `acer`, `vm`. Hardware lives
**inside the named host** and is never copied between hosts — each machine
has its own UUIDs, which validate with `lsblk -f` on the machine itself. In
desktop environments, GNOME/Plasma/Hyprland/Sway/Niri are *options*
(`hamra.desktop.default`), not hosts.

## Layers

| Layer | Contents |
|---|---|
| NixOS (`modules/nixos/`) | Program toggles: package, daemon, firewall, group, hardware permission |
| Home (`modules/home/`) | Declarative user config (zsh, terminal, editor, HM desktops) |
| `hosts/<machine>` | Atomic unit — identity, system choices, full true/false menus |

Hosts carry plain values; the library carries the implementation. Host roles
(NAS, VNC server) live on hosts: `acer` is the NAS, `samsung` runs wayvnc.
Repetition across hosts is normal — each file is the full menu, and `git
diff` shows exactly what differs between machines.

## Apps outside Nix

`hamra.mise.*` (tools, env, settings) generate `~/.config/mise/config.toml`
via HM; the `hamra-mise-install` service installs the declared tools on
activation (oneshot, `after home-manager-<user>.service`, re-runs when the
tools change). Flatpaks and webapps follow the same module pattern.

## Secrets

sops-nix + age: `secrets/*.yaml` encrypted; public keys per machine in
`.sops.yaml`; each host decrypts with the key derived from its own
`ssh_host_ed25519_key`. Nothing in plaintext enters the repo or the store.

## CI / Git Flow

CI on every push/PR: formatting (alejandra), lint (statix + deadnix),
evaluation (`nix flake check`) and build of all hosts' toplevels
(discovered dynamically). Every merge to `main` triggers `release.yml`,
which creates the next minor semver tag with notes generated from the
conventional commits. Flow: `feature/* -> PR -> main`.

## Updates

nixpkgs is pinned by `flake.lock` (`github:NixOS/nixpkgs/nixos-26.05`).
Updating = `nix flake update <input>` + rebuild. There is no auto-update:
input changes go through a PR like anything else.

## Directories

| Folder | Role |
|---|---|
| `flake/` | hosts, apps (deploy/build), devshell |
| `hosts/<machine>/` | atomic unit: identity, choices, full menus + hardware |
| `modules/` | the whole library (lib, nixos, home) |
| `apps/cookiecutter/` | CookieCutter — TUI machine shaper (bash + gum + fzf, no compilation) |
| `scripts/` | CLI engine (hamra-init), golden tests, NAS wizard |
| `scripts/` | assistants (e.g. setup-nas) |
| `secrets/` | encrypted secrets |
| `docs/` | guides (NAS for beginners, firewall) |
