# Hamra — Project Rules

Hamra is a NixOS + Home Manager **configuration library**. Each program is a
"book on the shelf": a self-contained file that declares its boolean option
and its implementation. To use one, just enable the toggle in
`hosts/<host>/programs-optionals.nix` (or `programs-core.nix`).

---

## Rules

### No comments in code

Comments are forbidden in module code (modules/, scripts, configs) — code
should explain itself: file names, option names and the `mkOption`
`description` fulfill that role. Documentation belongs in the `.md` files
(`README.md`, `SETUP.md`, `docs/`, this file).

### Language

English is the project standard for code, comments, documentation, commit
messages and user-facing messages.

### Layers: NixOS vs Home

Defines what goes in each layer:

| Layer | What to put there | Examples |
|---|---|---|
| **NixOS** (`modules/nixos/programs/{core,optionals}/`) | Program toggle modules — package installation, systemd daemon, firewall, user group, hardware permissions | `core/cli/grim`, `optionals/games/steam`, `core/noctalia/gpu-screen-recorder` |
| **Home** (`modules/home/programs/`) | Only declarative HM configuration logic (`programs.foo`), shell/terminal/editor config | zsh, foot, starship, aliases, neovim |

➡ All package installation goes in NixOS. Home is for config only.

### Categories by app shape

The category describes **how the app presents itself**, not its domain of use:

| Folder | Criterion | Examples |
|---|---|---|
| `gui/` | Opens a window | browsers, vscode, discord, bitwarden, obsidian, kodi, nautilus |
| `tui/` | Interface inside the terminal | btop, lazygit, yazi, lazydocker, cliamp |
| `cli/` | Command line / toolchain | git, ripgrep, fd, jq, gcc, python3, rclone |
| `services/` | Daemon / system integration | samba, docker, appimage, wayvnc, xdg, gtk |
| `media/` | Media playback and creation | mpv, spotify, spicetify, obs |
| `games/` | Games and launchers | steam, pcsx2, heroic, lutris |

Kept for specificity: `core/noctalia/` (Noctalia shell integration) and
`core/scripts/` (the repo's own scripts). Do not create a subcategory for
1 file; do not create a generic catch-all like "utility".

### Core vs Optional

Toggle modules are categorized into two tiers:

| Tier | `default` | Criterion |
|---|---|---|
| **Core** (infrastructure) | `true` | Dependency of scripts, called in keybinds, recurring desktop utility, part of the environment's base. Exceptions with `false`: `cli/git`, `gui/thunar` |
| **Optional** (personal choice) | `false` | Nothing breaks if turned off — AI agents, games, IDEs, media players, security tools |

Core programs can be explicitly disabled by anyone wanting a leaner
environment.

### mise vs Nix

The user keeps dev tools at `latest` via **mise** (`core/cli/mise`) and may
have the same tool installed by a Nix toggle at the same time — it is not a
forbidden duplicate, the contexts are different. PATH precedence: in the
interactive shell the mise hook (`mise activate` via `enableZshIntegration`)
keeps the shims in front, so `mise use -g` always wins over the Nix store;
outside the shell (daemons, desktop entries, services) only the Nix version
exists. If a host does not want the mise version of a tool, simply do not
install it via mise — the Nix toggle serves as the base/fallback.

### Apps by source (Nix, mise, flatpak, webapps)

The **`shelf`** command (toggle `core/scripts/apps`, default `true`)
lists what is installed and what can be installed, with the source of each
item:

- `shelf` — everything; `shelf -v go` — filter by name; `shelf --help`
- Installed via Nix: NixOS packages + Home Manager `home.packages` (read from
  the `/etc/hamra/apps.json` manifest, generated at build)
- Available via mise: `mise ls --json` + the catalog declared in `hamra.mise.tools`
- Flatpak: `flatpak list` (system and user) + those declared in `hamra.flatpak.apps`

Apps can be pre-set in Nix (can be used alongside the imperative mode):

| Option | What it does | Format |
|---|---|---|
| `hamra.mise.tools` | mise tools (via HM `globalConfig`) | `{ go = "latest"; node = ["lts" "22"]; }` |
| `hamra.mise.env` | mise `[env]` section | `{ _.path = ["~/bin"]; }` |
| `hamra.mise.settings` | mise `[settings]` section | `{ github_attestations = false; }` |
| `hamra.flatpak.apps` | installs via `flatpak-sync` oneshot on activation | `[ "app.dvd.DVDStyler" ]` |
| `hamra.webapps` | generates a wrapper + `.desktop` for a web app | `{ notion = { url = "..."; desktopName = "Notion"; }; }` |

The mise options require the `core/cli/mise` toggle enabled (build assertion);
the flatpak and webapps ones require their modules. `hamra.webapps.<name>.icon`
requires `iconHash`.

HM writes a **single** `~/.config/mise/config.toml` from
`hamra.mise.{tools,env,settings}`. Since the file becomes a symlink into the
store, do not edit it by hand: imperative and declarative management do not
coexist — pick one, or the build fails with "Existing file would be clobbered".

Tools outside the default registry use the full backend as the key:
`"github:herdrdev/herdr" = "latest"`.

`github_attestations = false` is a workaround for mise 2026.5.12 from nixpkgs,
which fails attestation verification (a Sigstore timestamp bug, fixed in
2026.10+). Remove it once the `nixpkgs` input is past that.

### Hosts are atomic units

Each host is self-contained: `hosts/<machine>/` carries
identity (hostname, user, locale, theme), system choices (hardware, boot,
audio, keyboard, display manager) and the full true/false menus
(`programs.core`, `programs.optionals`, home programs), split by toggle type:
`config/system.nix`, `config/hardware.nix`, `config/desktop.nix`, `config/programs-core.nix`,
`config/programs-optionals.nix`, `config/home.nix` (plus the `configuration.nix` import
shim and `hardware-configuration.nix`). Nothing is inherited
from shared layers — repetition across hosts is normal and expected.

Rules:
- Each line in a host file is a decision — the files are the full menu, not a
  delta. Disabled toggles stay visible as `= false`.
- Never hand-write host files: generate them with `cookiecutter` (answers file,
  wizard or `--from <host>` to inherit another host's optionals), which reads
  the toggle universes from the module files themselves.
- `flake/hosts.nix` discovers every directory under `hosts/` automatically.
- **Host role ≠ personal preference:** `samba`, `wayvnc`, `tigervnc` say
  *who the machine is* (NAS, VNC server) and are plain values on that host
  (e.g. `acer` is the NAS → `services.samba = true` on it). A new host created
  by `setup-nas.sh` must NOT become a NAS by accident.

Fork contract: hosts **never flow upstream**. Forks keep their own
`hosts/<machine>/` folders in their fork — they are never submitted in PRs.
Contributions are the library only (`modules/`, `flake/`, `docs/`), so pulls
stay conflict-free and every person's choices stay free. CI enforces this
with the `personal-layer guard` job (PRs touching `hosts/` fail unless a
maintainer adds the `personal-layer` label).

### Toggle module (NixOS)

One file per program. Declares the option + implementation together. The
`scanPaths` in the category's `default.nix` discovers them automatically.

```nix
{config, lib, pkgs, ...}: let
  cfg = config.hamra.programs.optionals.games.steam;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.steam = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Steam.";
  };

  config.programs.steam = mkIf cfg {
    enable = true;
  };
}
```

- Core: `options.hamra.programs.core.<category>.<name>`
- Optional: `options.hamra.programs.optionals.<category>.<name>`
- User (Home Manager): `options.hamra.home.programs.<category>.<name>`
- Hyphenated names need quotes: `"docker-compose"`
- The option path must match the file location:
  `optionals/tui/yazi.nix` → `optionals.tui.yazi`

### No hardcoded folder structure in code

Do not rely on fixed paths. Use `scanPaths` for auto-import whenever
possible. If a module needs to import another, use a path relative to the
current file.

### XDG portal

Each desktop defines its own portal in `compositor.nix` — each desktop is
self-contained. The `core/services/xdg` toggle only handles user dirs, MIME
and gvfs.

- Hyprland → `xdg-desktop-portal-hyprland`
- Sway → `xdg-desktop-portal-wlr`
- Niri → `xdg-desktop-portal-gtk`

### Hardware

Hardware options (GPU, firmware, bluetooth, touchpad, brightness) are
declared in specific modules, not in a central `options.nix`.

### Theme

Each theme defines wallpaper + profile icon for Noctalia and Silent SDDM.
The `hamra.theme.name` toggle switches everything automatically. Default
theme: `resident-evil`.

### Default browser

The acer host sets `browser = pkgs.chromium` (the module
default in `envs/env.nix` is `pkgs.helium`). To change it on a host:
`hamra.env.browser = pkgs.firefox;`

### Firewall and ports

`hamra.firewall` (in `config/system.nix`) is the named-port menu:

| Port | Opens |
|---|---|
| `ssh` (default `true`) | TCP 22 |
| `mosh` | UDP 60000-61000 |
| `http` | TCP 80 |
| `https` | TCP 443 |
| `dev` | TCP 3000-3001/4000/4200/5000-5001/5173-5174/8000-8001/8080-8082/9000/19000-19002 — test a local dev server from the phone (bind it to 0.0.0.0, e.g. `vite --host`) |
| `vnc` | TCP 5900 |
| `rdp` | TCP 3389 |
| `samba` | TCP 139/445 + UDP 137/138 |
| `syncthing` | TCP 8384/22000 + UDP 21027 |
| `kdeconnect` | TCP+UDP 1714-1764 |
| `jellyfin` | TCP 8096/8920 + UDP 1900/7359 |
| `printer` | TCP 631 + UDP 5353 |
| `mpd` | TCP 6600 |

`enable = false` disables the firewall (everything opens). Unknown names fail
the build (assertion in `core/firewall.nix`). The `wayvnc`, `samba` and
`localsend` toggles open their own ports when enabled — the menu is for
everything else.

### Build-time assertions

Validations: bootloader, GPU, firmware, audio,
desktop and display manager within their ranges; theme exists in the list;
locale with `.UTF-8`; required fields filled in; WayVNC only with Hyprland
or Sway; firewall port names within the registry (`core/firewall.nix`).

### NAS / Samba

The `hamra.programs.optionals.services.samba` toggle turns the host into an
SMB NAS (3 shares: `shared`, `games`, `backups`). Folders are created via
`systemd.tmpfiles.rules`. The shares have an **automatic trash bin** (VFS
`recycle`): files deleted over SMB go to the hidden `.trash` folder of each
share, keeping the structure and file versions. Limitations: it does not
protect against a direct `rm` on the server; it is a bumper against
accidents, not a backup. Guide: section 9 of `docs/nas-iniciantes.md`.

The Samba password is managed by **sops-nix**: the secret in
`secrets/samba.yaml` (encrypted) is applied automatically by
`system.activationScripts.sync-samba-password`
(the script uses `stringAfter ["setupSecrets"]` to run after sops-nix).
Key setup and client-side usage: see `README.md`/NAS section.

### New PC / new user (beginner-friendly assistant)

To replicate the NAS on ANY PC without knowing encryption/NixOS, there is
`scripts/setup-nas.sh` (installed as the `setup-nas` command by the
`core/scripts/setup-nas` toggle). It creates the host structure,
generates/registers keys in `.sops.yaml`, creates the user's own password in
`secrets/samba.yaml` (encrypted) and applies the rebuild — explaining each
step and how to fix errors. The generated host folder is a full
atomic host (see "Hosts are atomic units"). Modes: `--check`, `--mostrar-senha`, `--reset-senha`,
`--ajuda`. Full guide: `docs/nas-iniciantes.md`.

### Secrets (sops-nix)

- Secrets are stored **encrypted** in `secrets/*.yaml` in the repository.
- Keys (editing + per-host decryption) live in `.sops.yaml` at the root.
- Editing key: `~/.config/sops/age/keys.txt` (generated with `age-keygen`).
- Per-host key: `cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age`
- New host with a secret → add the pubkey to `.sops.yaml` + `nix develop --command sops updatekeys secrets/<file>`.
- Edit a secret: `nix develop --command sops secrets/<file>`.
- Never commit private keys or plaintext values.

---

## CI and quality

The repository has three checks on GitHub Actions:

| Check | What it does | How to avoid failure |
|---|---|---|
| Formatting | `alejandra --check .` | `nix fmt` before committing |
| Evaluation | `nix flake check` | `nix flake check` locally |
| Lint | `statix` + `deadnix` | `nix develop --command statix check . && nix develop --command deadnix .` |

### Tips

1. **`nix fmt`** before every commit
2. **Group repeated keys:** prefer `boot = { initrd.availableKernelModules = [...]; kernelModules = [...]; };` over two loose lines
3. **`hardware-configuration.nix`:** you may restructure it (group keys), but do not change UUIDs/devices
4. **Empty arguments:** use `_:` instead of `{ }:` when the function takes no arguments
5. **`inherit`:** prefer `inherit (nixpkgs) lib;` over `lib = nixpkgs.lib;`

### Useful commands

| Command | What it does |
|---|---|
| `nix fmt` | Formats all `.nix` files with alejandra |
| `nix develop` | Enters the devShell with tools |
| `nix flake check` | Evaluates the entire flake |
| `nix develop --command statix check .` | Runs the linter |
| `nix develop --command deadnix .` | Checks for dead code |
