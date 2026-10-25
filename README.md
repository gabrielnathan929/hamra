# Hamra

NixOS + Home Manager configuration for my machines, written as a library of
toggles: every program is a single file that declares its own boolean option
and its own implementation. I built it this way to know exactly what is
installed, understand each component straight in the code, and swap any piece
— GPU, desktop, browser, theme — by changing one line. It is not a distro
and does not try to configure everything: what lives here is as much as I
need.

## How it works

Each host is self-contained: `hosts/<name>/` carries
identity, system choices and the full true/false menus — nothing is inherited
from shared layers. Each line in a host file is a decision of that machine.
The files are split by toggle type (`config/system.nix`, `config/hardware.nix`,
`config/desktop.nix`, `config/programs-core.nix`, `config/programs-optionals.nix`, `config/home.nix`,
plus the `configuration.nix` import shim). The whole `samsung` starts like
this in `system.nix` (then the complete `programs.core`,
`programs.optionals` and home menus, every toggle visible):

```nix
{...}: {
  hamra = {
    networking.hostname = "samsung";

    users.userName = "gabrielnathan";

    locale = "pt_BR.UTF-8";
    timezone = "America/Sao_Paulo";
    theme.name = "dragon-ball";

    # ... every core/optional/home toggle, true or false
  };
}
```

Never hand-write them: `cookiecutter` generates the
files from the toggle modules themselves, so the menu never goes stale.

Three toggle families:

- `hamra.programs.core.<category>.<name>` — machine base, `default = true`.
  Boot, firewall-protected networking, locale, security (polkit, keyring,
  GnuPG, SSH) and recurring utilities. Turn them off by toggle for a leaner
  environment.
- `hamra.programs.optionals.<category>.<name>` — personal choice,
  `default = false`, switched in the host file:
  `optionals.gui.vscode`, `optionals.games.steam`,
  `optionals.services.docker`... Disabled toggles stay visible as `= false`,
  so the host file is the full menu.
- `hamra.home.programs.<category>.<name>` — Home Manager, user-level
  configuration (editor, shell, terminal). Package installation always stays
  in the NixOS layer; the home layer is config only.

The category describes the app's shape, not its domain: `gui/` opens a
window, `tui/` lives in the terminal, `cli/` is command line, `services/` is
a daemon, `media/` plays or produces media, `games/` is a game (optionals
also has `packaging/`). The option path mirrors the file path:
`optionals/tui/lazygit.nix` declares `hamra.programs.optionals.tui.lazygit` —
finding anything is always trivial.

Invalid combinations break the eval, not the boot: `core/assertions.nix`
rejects nonexistent GPUs, wrong themes, WayVNC outside Hyprland/Sway and the
like, with a message explaining why.

## What is installed

The `shelf` command lists everything, by source:

```bash
shelf              # Nix, mise, Flatpak and web apps, with versions
shelf <term>       # filter by name (case-insensitive)
shelf -v <tool>    # versions of <tool> available in the mise registry
```

The Nix part comes from a manifest (`/etc/hamra/apps.json`) generated at
build time from the modules themselves — there is no manual list to go
stale. Anything declared but not installed yet shows up marked (mise and
Flatpak).

## Apps outside Nix

| Option | What it does |
|---|---|
| `hamra.mise.tools` | mise tools in `~/.config/mise/config.toml` (via HM) |
| `hamra.flatpak.apps` | installs Flathub IDs through the `flatpak-sync` service |
| `hamra.webapps` | wrapper + `.desktop` that open the site in its own window |

Each one requires the corresponding module enabled (build-time assertion).
Whoever uses mise imperatively declares the tools there, not in Nix. Web app
example:

```nix
hamra.webapps.notion = {
  url = "https://www.notion.so";
  desktopName = "Notion";
};
```

## Adding a new app

One file, one toggle. Real example —
`modules/nixos/programs/optionals/tui/lazygit.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.lazygit;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.lazygit = mkOption {
    type = types.bool;
    default = false;
    description = "Enable lazygit (TUI for git).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [lazygit]);
}
```

Package in the NixOS layer, user config in `modules/home/`. `scanPaths`
discovers the file on its own, no manual import. Enable it in the host file.
Loose package without a module: `hamra.packages.extra = [pkgs.foo];`.

Forking for personal use: generate your hosts with `cookiecutter`
and keep the `hosts/<machine>/` folders in your fork.
Your hosts are yours alone and never flow upstream — CI blocks PRs
that touch them — and your fork is their version control (see
CONTRIBUTING.md, "Versioning your personal layers"). Pulling updates stays
conflict-free and your choices stay yours.

## Steam: non-Steam games, Proton and artwork

The `games.steam` toggle ships Proton-GE (`proton-ge-bin` as a
compatibility tool) and exposes `mangohud`, `gamemode` and `gamescope`
inside the Steam runtime, so `gamescope ... -- gamemoderun mangohud
%command%` works as a launch option. A Windows installer that spins
forever under plain Wine usually runs fine under Proton: add the
`setup.exe` as a non-Steam game, force GE-Proton in its properties,
and install into the Steam `compatdata` prefix. The `games.umu`
toggle provides the same Proton outside Steam (`umu-run` with one
`WINEPREFIX` per game). The toggle also links the `proton-ge-bin`
build from the nix store into
`~/.local/share/Steam/compatibilitytools.d`, so a Proton version
exists even if Steam is never installed.

## Proton builds: Hydra, umu and ProtonUp-Qt

Proton versions are read from
`~/.local/share/Steam/compatibilitytools.d`, which is shared by
`umu-run`, Hydra and Steam — Steam itself is not required to be
running (or installed). The `games.protonup-qt` toggle installs
ProtonUp-Qt, the GUI that downloads and updates builds
(GE-Proton, UMU-Proton, Proton-EM and Steam's own) into that
directory. On the first run keep the default install directory
(`~/.local/share/Steam/compatibilitytools.d`); the GE-Proton build
from the nix store is already there whenever `games.umu` is on.

The `games.hydralauncher` toggle installs Hydra through a wrapper
(`hydra`, also the menu entry) that puts `python3`, `umu-launcher`,
`gamemoderun`, `mangohud` and `winetricks` on its PATH, so the
GameMode and MangoHud toggles in Hydra's settings are detected and
the Winetricks button works. Hydra has no gamescope option; its own
GameMode/MangoHud switches stay in the app settings (Behavior
section) and now flip on and off as expected. The wrapper also
keeps the umu-launcher runtime complete: `~/.local/share/umu/steamrt*`
must be a real directory owned by umu (it downloads its own Steam
Linux Runtime from Valve), never a shortcut pointing at Steam's
copy; a leftover shortcut is removed before launch and umu
re-installs its own runtime. GameMode runs with the `performance`
governor (see `programs.gamemode.settings`) and the MangoHud overlay
layout comes from the `home.programs.games.mangohud` toggle
(`~/.config/MangoHud/MangoHud.conf`).

Artwork for non-Steam shortcuts comes from BoilR (`games.boilr`,
auto-enabled wherever Steam is on). One-time setup: quit Steam, open
BoilR, paste a free SteamGridDB API key in Settings, set the Steam
location to `~/.local/share/Steam`, enable stop/start Steam around
the import, then Import. Repeat the import whenever a new shortcut is
added; rename the shortcut to the exact title if a game gets the
wrong art.

## Game streaming: Sunshine and Moonlight

The pair replaces Parsec when it does not work for you. The machine that
**serves** the stream enables `services.sunshine` (the host, a daemon that
captures the screen and streams it); the machine you play **from** enables
`gui.moonlight` (the client). Both hosts currently have both toggles on, so
either machine can be the host or the client.

Sunshine opens its own ports (TCP 47984/47989/47990/48010, UDP
47998-48002/48010) — the firewall menu needs no extra entry. First use is
done in the web UI: open `https://<host>:47990`, create a user and password,
add the apps you want to stream (Steam, the desktop, emulators). Pairing is
from the Moonlight side: it finds the host on the network (avahi) or you type
the address manually. The `cap_sys_admin` capability is on so the KMS/DRM
capture works under Hyprland without a screencast portal.

## Theme

`hamra.theme.name` switches wallpaper, profile icon and videos at once — the
profile icon feeds the login screen, the wallpaper the shell. Each theme is a
folder in `modules/nixos/core/theme/themes/` (currently `dragon-ball`). The window icon theme (Papirus) and the
cursor (Bibata) are fixed parts of the base theme.

## Commands

| Command | What it does |
|---|---|
| `nix fmt` | formats everything (alejandra) |
| `nix flake check` | evaluates all hosts + assertions |
| `nix develop` | shell with statix, deadnix, sops, age, ssh-to-age |
| `nix run .#build-<host>` | build without applying (saved in `./result`) |
| `nix run .#deploy-<host>` | `nix flake check` + `nixos-rebuild switch` |
| `nix run .#cookiecutter` | wizard that generates a new host (gum/fzf when available, `--from <host>` inherits its optionals) |
| `keys [context]` | keybinds of the active WM, `tmux`, `herdr` or `all` |

On the desktop, `SUPER+K` opens the compositor keybinds in an interactive
search; `SUPER+CTRL+K` and `SUPER+ALT+K` bring the Herdr and Tmux menus.
Inside tmux, `Prefix + ?` opens the same panel in a popup.

Registered hosts: `samsung`, `acer`, `vm` (`x86_64-linux` only). CI runs
formatting, lint (`statix` + `deadnix --fail`), evaluation and the build of every
host on each push.

## NAS

The `services.samba` toggle turns a host into an SMB NAS (shares `shared`,
`games`, `backups`, each with an automatic `.trash` recycle bin). Only the
machine that **serves** the files enables it — clients just mount the shares
and need nothing enabled. The password
lives encrypted in `secrets/samba.yaml` (sops-nix). On any PC, `setup-nas`
does the whole onboarding (host files, keys, password, rebuild):

```bash
nix develop
./scripts/setup-nas.sh              # guided assistant
./scripts/setup-nas.sh --check      # environment audit, changes nothing
./scripts/setup-nas.sh --show-password
./scripts/setup-nas.sh --reset-password
./scripts/setup-nas.sh --help
```

Full guide: `./scripts/setup-nas.sh --help` and `SETUP.md` section 3.

## Further reading

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — where the configuration that boots each machine comes from
- [`SETUP.md`](SETUP.md) — install NixOS and bring up Hamra on a new machine
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — Git Flow, local validation, golden rules
- [`SECURITY.md`](SECURITY.md) — secrets (sops) and vulnerability reporting
- [`AGENTS.md`](AGENTS.md) — repo rules: layers, categories, toggle modules

## License

[MIT](LICENSE).
