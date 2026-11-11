# Hamra

**A NixOS + Home Manager configuration library that lets you build reproducible, declarative desktops by flipping toggles — no copy-pasting, no drift, no "it works on my machine."**

---

## The Problem

You maintain multiple Linux machines. Each one accumulates unique tweaks over time. Reproducing a setup means reading old notes, copying dotfiles, debugging why `hyprland` works on the laptop but not the desktop. NixOS solves reproducibility, but raw NixOS configs are verbose, coupled, and hard to share across machines without inheritance hierarchies that leak.

---

## What Hamra Gives You

| Pain Point | Hamra's Answer |
|------------|----------------|
| **Config drift across machines** | Every host is a self-contained file tree generated from the same toggle modules — same code, different boolean values |
| **Monolithic `configuration.nix`** | Split by concern: `system.nix`, `hardware.nix`, `desktop.nix`, `programs-core.nix`, `programs-optionals.nix`, `home.nix` |
| **Adding a program = editing 3 files** | One module file declares the option + implementation. Enable with `programs.optionals.gui.vscode = true;` |
| **Package vs config confusion** | Hard rule: **NixOS layer = packages/services**, **Home Manager layer = user config only** |
| **Secrets in plaintext or scattered** | `sops-nix + age`: encrypted `secrets/*.yaml` in repo, decrypted at boot to `/run/secrets/` |
| **"Which version of Node/Go/Rust do I have?"** | `mise` for dev tools (per-project, per-user), Nix for system packages — `shelf` command shows everything |
| **New machine setup takes hours** | `cookiecutter` wizard → generates complete host folder → `nixos-rebuild switch` → done |
| **Breaking changes silently** | Build-time assertions: invalid GPU/desktop combos, missing secrets, wrong themes fail at *eval*, not boot |

---

## Core Concepts

### Toggle Modules (The Unit of Composition)
Every program is one file: `modules/nixos/programs/optionals/gui/vscode.nix`
```nix
{ config, lib, pkgs, ... }: let
  cfg = config.hamra.programs.optionals.gui.vscode;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.gui.vscode = mkOption {
    type = types.bool; default = false;
    description = "Enable VS Code.";
  };
  config = mkIf cfg { environment.systemPackages = [ pkgs.vscode ]; };
}
```
**Enable in host:** `hamra.programs.optionals.gui.vscode = true;` — that's it.

### Three Toggle Tiers
| Tier | Prefix | Default | Philosophy |
|------|--------|---------|------------|
| **Core** | `hamra.programs.core.*` | `true` | Infrastructure: boot, firewall, SSH, polkit, keyring — turn off for minimal |
| **Optional** | `hamra.programs.optionals.*` | `false` | Personal apps: editors, games, media, AI — opt-in only |
| **Home** | `hamra.home.programs.*` | varies | User config: zsh, nvim, foot, keybinds, aliases — no packages |

### Categories by *Shape*, Not Domain
```
cli/      → command-line tools (git, ripgrep, fd, jq)
tui/      → terminal UIs (btop, lazygit, yazi, lazydocker)
gui/      → windowed apps (firefox, vscode, discord, obsidian)
services/ → daemons (docker, samba, wayvnc, xdg-desktop-portal)
media/    → playback/creation (mpv, spotify, obs)
games/    → launchers + tooling (steam, proton, umu, mangohud)
```

---

## Tooling You Get

| Tool | Purpose |
|------|---------|
| **`shelf`** | Unified inventory: Nix packages + mise tools + Flatpaks + webapps — versions, sources, install status |
| **`cookiecutter`** | Interactive wizard (gum/fzf) that generates a complete `hosts/<name>/` from the module registry |
| **`nix run .#deploy-<host>`** | One command: flake check + lint + build + `nixos-rebuild switch` |
| **`keys <context>`** | Searchable keybind cheatsheet for Hyprland/Niri/Sway, tmux, herdr |
| **`hamra-saves`** | Adopt/detach game saves across Wine prefixes into `~/Saves/<game>` |
| **`setup-nas`** | Guided onboarding: generates host, registers keys, encrypts Samba password, rebuilds |
| **`capture`** | Screen recording (no audio / desktop / desktop + mic / + webcam overlay) and screenshots — `Alt+Print` opens the capture launcher (`/cap`), or run `capture` from a terminal |

---

## Documentation Map

| Need | Read |
|------|------|
| **Install NixOS + bootstrap Hamra** | [`SETUP.md`](SETUP.md) |
| **How the module system works** | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| **Contribute / Git Flow / local CI** | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| **Secrets (sops/age): keys, workflows, troubleshooting** | [`docs/sops.md`](docs/sops.md) |
| **Samba NAS: shares, trash, mounting, keys** | [`docs/nas.md`](docs/nas.md) |
| **Remote desktop (VNC): server, clients, credentials** | [`docs/vnc.md`](docs/vnc.md) |
| **Firewall: named ports, service-owned ports** | [`docs/firewall.md`](docs/firewall.md) |
| **Repo rules: layers, categories, toggles** | [`AGENTS.md`](AGENTS.md) |

---

## Quick Start (New Machine)

```bash
# 1. Install NixOS (minimal, no DE) — see SETUP.md
# 2. Clone your fork
git clone https://github.com/YOUR-USER/hamra
cd hamra

# 3. Enter dev shell (statix, deadnix, alejandra, sops, age, ssh-to-age, gum, fzf...)
nix develop

# 4. Generate host config (interactive)
nix run .#cookiecutter
# → answers hostname, user, GPU, desktop, theme, core/optional toggles

# 5. Build & apply
sudo nixos-rebuild switch --flake .#your-hostname
```

---

## Fork-Friendly by Design

- **Upstream** = library only (`modules/`, `flake/`, `docs/`, scripts)
- **Your fork** = `hosts/<your-machines>/` + any private modules
- CI **blocks PRs touching `hosts/`** — your machines never flow upstream
- Pull upstream updates conflict-free; your choices stay yours

---

## Current Hosts (Reference)

| Host | Role | Desktop | GPU | Notable Toggles |
|------|------|---------|-----|-----------------|
| `samsung` | Daily driver laptop | Hyprland | Intel | wayvnc (server), steam, sunshine, moonlight |
| `acer` | NAS / desktop | Hyprland | Intel | samba, vnc-client (auto TigerVNC), steam, protonup-qt |
| `vm` | Test VM | Hyprland | virtio | minimal, no wayvnc/samba |

---

## Requirements

- NixOS 24.11+ (flakes enabled)
- x86_64-linux (ARM64 untested)
- `git`, `ssh` for host key derivation

---

## License

[MIT](LICENSE) — use it, fork it, build on it.