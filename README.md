# Hamra

NixOS + Home Manager configuration for my machines, written as a library of
toggles: every program is a single file that declares its own boolean option
and its own implementation. I built it this way to know exactly what is
installed, understand each component straight in the code, and swap any piece
— GPU, desktop, browser, theme — by changing one line. It is not a distro
and does not try to configure everything: what lives here is as much as I
need.

## How it works

Configuration is split in three layers merged by NixOS option priority:
`hosts/common/` is the shared machine baseline (no personal values),
`hosts/profiles/<owner>/` is the personal profile (apps on, username, theme,
mise tools) and `hosts/<name>/` holds only machine deltas — identity,
hardware and roles. A host imports the baseline plus a profile; each line in
a host file is a decision of that machine. The whole `samsung` is this:

```nix
_: {
  imports = [
    ../../modules/nixos/core
    ../../modules/nixos/desktops
    ../../modules/nixos/programs
    ../common
    ../profiles/gabrielnathan
    ./hardware-configuration.nix
  ];

  hamra = {
    networking.hostname = "samsung";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    keyboard = {
      keymap = "us";
      xkbVariant = "intl";
    };

    desktop.default = "hyprland";
  };
}
```

Three toggle families:

- `hamra.programs.core.<category>.<name>` — machine base, `default = true`.
  Boot, firewall-protected networking, locale, security (polkit, keyring,
  GnuPG, SSH) and recurring utilities. Turn them off by toggle for a leaner
  environment.
- `hamra.programs.optionals.<category>.<name>` — personal choice,
  `default = false`, enabled through the owner profile in
  `hosts/profiles/`: `optionals.gui.vscode`, `optionals.games.steam`,
  `optionals.services.docker`... A host that does not want something from
  the profile declares `= false` on itself.
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

The `hamra-apps` command lists everything, by source:

```bash
hamra-apps              # Nix, mise, Flatpak and web apps, with versions
hamra-apps <term>       # filter by name (case-insensitive)
hamra-apps -v <tool>    # versions of <tool> available in the mise registry
```

The Nix part comes from a manifest (`/etc/hamra/apps.json`) generated at
build time from the modules themselves — there is no manual list to go
stale. Anything declared but not installed yet shows up marked (mise and
Flatpak).

## Apps outside Nix

| Option | What it does |
|---|---|
| `hamra.mise.tools` | mise tools in `~/.config/mise/config.toml` (via HM) |
| `hamra.flatpak.apps` | installs Flathub IDs through the `hamra-flatpak` service |
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

(`optionals/gui/notion.nix` is exactly this block behind a toggle.)

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
discovers the file on its own, no manual import. Enable it in your profile
(`hosts/profiles/<owner>/`) if it applies to every machine, or in the host.
Loose package without a module: `hamra.packages.extra = [pkgs.foo];`.

Forking for personal use: copy `hosts/profiles/gabrielnathan` under your own
name, edit it (username, theme, apps) and point your hosts at it. Your hosts
and your profile are yours alone and never flow upstream — CI blocks PRs
that touch them — and your fork is their version control (see
CONTRIBUTING.md, "Versioning your personal layers"). Pulling updates stays
conflict-free and your choices stay yours.

## Theme

`hamra.theme.name` switches wallpaper, profile icon and videos at once — the
profile icon feeds the login screen, the wallpaper the shell. Themes:
`dragon-ball`, `evangelion`, `resident-evil` (each one is a folder in
`modules/nixos/core/theme/themes/`). The window icon theme (Papirus) and the
cursor (Bibata) are fixed parts of the base theme.

## Commands

| Command | What it does |
|---|---|
| `nix fmt` | formats everything (alejandra) |
| `nix flake check` | evaluates all hosts + assertions |
| `nix develop` | shell with statix, deadnix, sops, age, ssh-to-age |
| `nix run .#build-<host>` | build without applying (saved in `./result`) |
| `nix run .#deploy-<host>` | `nix flake check` + `nixos-rebuild switch` |
| `hamra-keybinds [context]` | keybinds of the active WM, `tmux`, `herdr` or `all` |

On the desktop, `SUPER+K` opens the compositor keybinds in an interactive
search; `SUPER+CTRL+K` and `SUPER+ALT+K` bring the Herdr and Tmux menus.
Inside tmux, `Prefix + ?` opens the same panel in a popup.

Registered hosts: `samsung`, `acer`, `vm` (`x86_64-linux` only). CI runs
formatting, lint (`statix` + `deadnix`), evaluation and the build of every
host on each push.

## Further reading

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — where the configuration that boots each machine comes from
- [`SETUP.md`](SETUP.md) — install NixOS and bring up Hamra on a new machine
- [`CONTRIBUTING.md`](CONTRIBUTING.md) — Git Flow, local validation, golden rules
- [`SECURITY.md`](SECURITY.md) — secrets (sops) and vulnerability reporting
- [`docs/nas-iniciantes.md`](docs/nas-iniciantes.md) — set up the NAS (Samba + secrets) on any PC
- [`docs/firewall-iptables.md`](docs/firewall-iptables.md) — iptables firewall / advanced rules
- [`AGENTS.md`](AGENTS.md) — repo rules: layers, categories, toggle modules

## License

[MIT](LICENSE).
