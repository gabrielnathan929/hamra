#!/usr/bin/env python3
"""hamra-init — generate an atomic Hamra host from answers, validate it, guide the rebuild.

Each host is self-contained: hosts/<name>/configuration.nix carries identity,
system choices and the full true/false menus. Nothing is inherited from shared
layers. Toggle universes and their defaults are read from the module files
themselves (single nix eval per tree), so generation can never drift from the
toggle modules. Scalar system choices use PROJECT_DEFAULTS below, the same
values every host carries explicitly.

Usage:
  hamra-init                       interactive wizard
  hamra-init --answers a.json      non-interactive
  hamra-init --dry-run             print the files, write nothing
  hamra-init --check               read-only environment audit
  hamra-init --gates-only <host>   re-run the validation gates for an existing host
"""

import argparse
import getpass
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HOSTNAME_RE = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9-]*$")
USER_RE = re.compile(r"^[a-z_][a-z0-9_-]*$")
PKGS_RE = re.compile(r"^[a-zA-Z0-9_.-]+$")
MIN_FREE_GB = 5
WARN_FREE_GB = 15
RESERVED = ("common", "profiles")

PROJECT_DEFAULTS = {
    "locale": "pt_BR.UTF-8",
    "timezone": "America/Sao_Paulo",
    "theme": "dragon-ball",
    "keyboard": {"keymap": "br", "xkbVariant": "abnt2"},
    "displayManager": "sddm",
    "audio": {"default": "pipewire"},
    "boot": {
        "grub": {"device": "/dev/sda", "useOSProber": False},
        "loader": "systemd-boot",
        "systemd": {"editor": False},
    },
    "desktop": {"default": "hyprland"},
    "sddm": {"theme": "silent", "preset": "catppuccin-mocha"},
    "gc": {
        "enable": True,
        "keepDays": 30,
        "maxGenerations": 20,
        "schedule": "weekly",
    },
    "mobile": {"android": False},
    "printing": True,
    "services": {"gnupg": True, "keyring": True, "polkit": True, "sshd": True},
    "hardware_extra": {"bluetooth": True, "brightness": True, "touchpad": True},
    "mise": {"env": {}, "settings": {}, "tools": {}},
    "env": {
        "editor": "neovim",
        "browser": "chromium",
        "terminal": "foot",
        "filemanager": "thunar",
    },
}

SECTION_ORDER = [
    "networking.hostname",
    "users.userName",
    "locale",
    "timezone",
    "theme.name",
    "hardware",
    "keyboard",
    "audio",
    "boot",
    "desktop",
    "displayManager",
    "displays",
    "gc",
    "mobile",
    "printing",
    "services",
    "env",
    "mise",
    "flatpak.apps",
    "packages.extra",
    "webapps",
    "programs.core",
    "programs.optionals",
]


def die(msg, hint=""):
    print(f"error: {msg}", file=sys.stderr)
    if hint:
        print(hint, file=sys.stderr)
    sys.exit(1)


def info(msg):
    print(f"  {msg}")


def ok(msg):
    print(f"ok: {msg}")


def warn(msg):
    print(f"warn: {msg}", file=sys.stderr)


def run(cmd, cwd=None, check=True, capture=False):
    printable = " ".join(str(c) for c in cmd)
    if capture:
        r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
        if check and r.returncode != 0:
            die(f"command failed: {printable}", r.stderr.strip())
        return r
    r = subprocess.run(cmd, cwd=cwd)
    if check and r.returncode != 0:
        die(f"command failed (exit {r.returncode}): {printable}")
    return r


def repo_root():
    env = os.environ.get("HAMRA_REPO")
    root = Path(env) if env else Path.cwd()
    if not (root / "flake.nix").is_file():
        die(
            "repository not found",
            "Run from the Hamra checkout (or set HAMRA_REPO). Expected flake.nix here:\n"
            f"  {root}",
        )
    return root


def load_enums(repo):
    r = run(
        ["nix", "eval", "--json", "--file", str(repo / "modules/lib/enums.nix")],
        cwd=repo,
        capture=True,
    )
    return json.loads(r.stdout)


def scanned_hosts(repo):
    hosts = repo / "hosts"
    return sorted(
        e.name for e in hosts.iterdir() if e.is_dir() and not e.name.startswith(".")
    )


def toggle_files(repo, tree):
    base = repo / "modules/nixos/programs" / tree
    found = []
    for category in sorted(e.name for e in base.iterdir() if e.is_dir()):
        for module in sorted((base / category).glob("*.nix")):
            if module.name != "default.nix":
                found.append((category, str(module)))
    return found


def toggle_universe(repo, tree):
    repo = Path(repo).resolve()
    entries = toggle_files(repo, tree)
    paths = " ".join(f'"{p}"' for _, p in entries)
    expr = (
        "let flake = builtins.getFlake \""
        + str(repo)
        + "\"; lib = flake.inputs.nixpkgs.lib; "
        + "hamraLib = import (flake.outPath + \"/modules/lib\") { inherit lib; }; "
        + "load = f: import f { config = {}; inherit lib; pkgs = {}; "
        + "hostName = \"hamra-init\"; inputs = flake.inputs; self = flake; inherit hamraLib; }; "
        + "walk = prefix: node: "
        + "if builtins.isAttrs node && (node._type or \"\") == \"option\" "
        + "then [{ path = prefix; default = node.default or null; }] "
        + "else if builtins.isAttrs node "
        + "then builtins.concatLists "
        + "(lib.mapAttrsToList (n: v: walk (prefix ++ [n]) v) node) "
        + "else []; "
        + "perfile = f: walk [] (load f).options.hamra; "
        + "in builtins.concatLists (map perfile [ "
        + paths
        + " ])"
    )
    r = run(
        ["nix", "eval", "--impure", "--json", "--expr", expr],
        cwd=repo,
        capture=True,
    )
    try:
        items = json.loads(r.stdout)
    except json.JSONDecodeError:
        die(f"could not read toggle defaults for {tree}", r.stdout[-2000:])
    universe = {}
    skipped = []
    for item in items:
        path = item["path"]
        if len(path) < 4 or path[:2] != ["programs", tree]:
            skipped.append("hamra." + ".".join(path))
            continue
        category, app = path[2], ".".join(path[3:])
        default = item["default"]
        if not isinstance(default, bool):
            die(
                f"toggle {tree}.{category}.{app} has non-bool default {default!r} — "
                "hamra-init only generates bool toggles; handle it explicitly"
            )
        universe.setdefault(category, {})[app] = default
    if skipped:
        warn(f"{tree}: ignoring non-toggle options: {', '.join(sorted(set(skipped)))}")
    return universe


def home_universe(repo):
    repo = Path(repo).resolve()
    base = repo / "modules/home/programs"
    entries = []
    for category in sorted(e.name for e in base.iterdir() if e.is_dir()):
        for module in sorted((base / category).glob("*.nix")):
            if module.name != "default.nix":
                entries.append(str(module))
    paths = " ".join(f'"{p}"' for p in entries)
    expr = (
        "let flake = builtins.getFlake \""
        + str(repo)
        + "\"; lib = flake.inputs.nixpkgs.lib; "
        + "load = f: import f { config = {}; inherit lib; pkgs = {}; }; "
        + "walk = prefix: node: "
        + "if builtins.isAttrs node && (node._type or \"\") == \"option\" "
        + "then [{ path = prefix; default = node.default or null; }] "
        + "else if builtins.isAttrs node "
        + "then builtins.concatLists "
        + "(lib.mapAttrsToList (n: v: walk (prefix ++ [n]) v) node) "
        + "else []; "
        + "perfile = f: walk [] (load f).options.hamra.home.programs or {}; "
        + "in builtins.concatLists (map perfile [ "
        + paths
        + " ])"
    )
    r = run(
        ["nix", "eval", "--impure", "--json", "--expr", expr],
        cwd=repo,
        capture=True,
    )
    try:
        items = json.loads(r.stdout)
    except json.JSONDecodeError:
        die("could not read home toggle defaults", r.stdout[-2000:])
    universe = {}
    for item in items:
        path = item["path"]
        if len(path) < 2:
            continue
        category, app = path[0], ".".join(path[1:])
        default = item["default"]
        if not isinstance(default, bool):
            die(
                f"home toggle {category}.{app} has non-bool default {default!r} — "
                "hamra-init only generates bool toggles; handle it explicitly"
            )
        universe.setdefault(category, {})[app] = default
    return universe


def parse_answers_file(path):
    try:
        with open(path) as f:
            a = json.load(f)
    except (OSError, json.JSONDecodeError) as e:
        die(f"cannot read answers file {path}: {e}")
    return a


def ask_enum(label, options, default=None):
    opts = " | ".join(options)
    while True:
        suffix = f" [{default}]" if default else ""
        raw = input(f"{label} ({opts}){suffix}: ").strip()
        if not raw and default:
            return default
        if raw in options:
            return raw
        warn(f"'{raw}' is not one of: {' | '.join(options)}")


def ask_hostname(existing):
    while True:
        raw = input("Machine name (becomes hostname and hosts/<name>): ").strip()
        if not HOSTNAME_RE.match(raw):
            warn("use letters, numbers and hyphens (must not start with a hyphen)")
            continue
        if raw in RESERVED:
            warn("'common' and 'profiles' are reserved")
            continue
        if raw in existing:
            warn(f"hosts/{raw} already exists — hamra-init never overwrites (write-once)")
            continue
        return raw


def ask_yes_no(label, default=False):
    suffix = " [Y/n]" if default else " [y/N]"
    while True:
        raw = input(f"{label}{suffix}: ").strip().lower()
        if not raw:
            return default
        if raw in ("y", "yes", "n", "no"):
            return raw in ("y", "yes")


def ask_keyboard():
    if not ask_yes_no(
        f"Custom keyboard for this machine? (default is the base "
        f"{PROJECT_DEFAULTS['keyboard']['keymap']}/{PROJECT_DEFAULTS['keyboard']['xkbVariant']})"
    ):
        return None
    keymap = input("  keymap (e.g. us, br): ").strip() or "us"
    variant = input("  xkbVariant (e.g. intl, abnt2 — empty for none): ").strip()
    return {"keymap": keymap, "xkbVariant": variant} if variant else {"keymap": keymap}


def ask_app_list(label):
    print(f"{label} (comma-separated cat.app, empty = defaults): ")
    raw = input("  ").strip()
    return [s.strip() for s in raw.split(",") if s.strip()]


def detect_gpu():
    lspci = shutil.which("lspci")
    if not lspci:
        return None
    try:
        out = subprocess.run([lspci], capture_output=True, text=True).stdout.lower()
    except OSError:
        return None
    if "virtio" in out and ("vga" in out or "display" in out):
        return "virtio"
    if "nvidia" in out:
        return "nvidia"
    if "amd" in out or ("ati" in out and "radeon" in out):
        return "amd"
    if "intel" in out:
        return "intel"
    return None


def detect_firmware():
    return "uefi" if Path("/sys/firmware/efi").is_dir() else "bios"


def hardware_config_source(repo):
    candidates = [
        Path("/etc/nixos.pre-hamra/hardware-configuration.nix"),
        Path("/etc/nixos/hardware-configuration.nix"),
    ]
    for c in candidates:
        if c.is_file() and "hamra" not in str(c.resolve()):
            return c.read_text(), str(c)
    gen = shutil.which("nixos-generate-config")
    if gen:
        r = run([gen, "--show-hardware-config"], cwd=repo, capture=True)
        return r.stdout, "nixos-generate-config --show-hardware-config"
    r = run(
        [
            "nix",
            "shell",
            "nixpkgs#nixos-install-tools",
            "-c",
            "nixos-generate-config",
            "--show-hardware-config",
        ],
        cwd=repo,
        capture=True,
    )
    return r.stdout, "nixos-generate-config --show-hardware-config"


def check_toggle_list(name, values, universe):
    for path in values:
        category, _, app = path.partition(".")
        if not _ or category not in universe or app not in universe.get(category, {}):
            die(f"unknown app in {name}: '{path}' — not a declared toggle")


def validate_answers(a, enums, existing, universes):
    required = {
        "hostname",
        "username",
        "gpu",
        "firmware",
        "desktop",
        "nas",
        "vnc",
    }
    missing = required - set(a)
    if missing:
        die(f"answers file is missing keys: {', '.join(sorted(missing))}")
    if not HOSTNAME_RE.match(a["hostname"]):
        die(f"invalid hostname '{a['hostname']}' (letters, numbers, hyphens)")
    if a["hostname"] in RESERVED:
        die("'common' and 'profiles' are reserved names")
    if a["hostname"] in existing:
        die(f"hosts/{a['hostname']} already exists — hamra-init never overwrites (write-once)")
    if not USER_RE.match(a["username"]):
        die(f"invalid username '{a['username']}'")
    for key in ("locale", "timezone", "theme"):
        if key in a and (not a[key] or not isinstance(a[key], str)):
            die(f"'{key}' must be a non-empty string")
    if a["gpu"] not in enums["gpus"]:
        die(f"invalid gpu '{a['gpu']}' — use one of: {' | '.join(enums['gpus'])}")
    if a["firmware"] not in enums["firmware"]:
        die(f"invalid firmware '{a['firmware']}' — use one of: {' | '.join(enums['firmware'])}")
    if a["desktop"] not in enums["desktops"]:
        die(f"invalid desktop '{a['desktop']}' — use one of: {' | '.join(enums['desktops'])}")
    if "displayManager" in a and a["displayManager"] not in enums["displayManagers"]:
        die(
            f"invalid displayManager '{a['displayManager']}' — "
            f"use one of: {' | '.join(enums['displayManagers'])}"
        )
    env = a.get("env") or PROJECT_DEFAULTS["env"]
    for key in ("editor", "browser", "terminal", "filemanager"):
        if key not in env or not PKGS_RE.match(env[key]):
            die(f"env.{key} must be a nixpkgs attribute name like 'foot'")
    if a.get("vnc") and a["desktop"] not in ("hyprland", "sway"):
        die("wayvnc requires desktop hyprland or sway (assertion rule)")
    check_toggle_list("enable", a.get("enable", []), universes["optionals"])
    check_toggle_list("disable", a.get("disable", []), universes["optionals"])
    check_toggle_list("core_enable", a.get("core_enable", []), universes["core"])
    check_toggle_list("core_disable", a.get("core_disable", []), universes["core"])
    check_toggle_list("hm_enable", a.get("hm_enable", []), universes["home"])
    check_toggle_list("hm_disable", a.get("hm_disable", []), universes["home"])
    kb = a.get("keyboard")
    if kb is not None and not kb.get("keymap"):
        die("keyboard.keymap cannot be empty when keyboard is set")
    for name, app in a.get("webapps", {}).items():
        if not app.get("url") or not app.get("desktopName"):
            die(f"webapps.{name} needs url and desktopName")


def collect_answers(enums, existing, args):
    detected_gpu = detect_gpu()
    gpu_default = detected_gpu or "intel"
    detected_fw = detect_firmware()

    username_default = getpass.getuser()
    a = {
        "hostname": ask_hostname(existing),
        "username": input(f"Username [{username_default}]: ").strip() or username_default,
        "locale": input(f"Locale [{PROJECT_DEFAULTS['locale']}]: ").strip()
        or PROJECT_DEFAULTS["locale"],
        "timezone": input(f"Timezone [{PROJECT_DEFAULTS['timezone']}]: ").strip()
        or PROJECT_DEFAULTS["timezone"],
        "theme": input(f"Theme [{PROJECT_DEFAULTS['theme']}]: ").strip()
        or PROJECT_DEFAULTS["theme"],
        "gpu": ask_enum("GPU", enums["gpus"], gpu_default),
        "firmware": ask_enum("Firmware", enums["firmware"], detected_fw),
        "desktop": ask_enum("Desktop", enums["desktops"], "hyprland"),
        "displayManager": ask_enum(
            "Display manager", enums["displayManagers"], PROJECT_DEFAULTS["displayManager"]
        ),
        "keyboard": ask_keyboard(),
        "nas": ask_yes_no("Is this machine the NAS (Samba)?"),
        "vnc": ask_yes_no("Run the wayvnc server here?"),
        "env": {
            "editor": input(f"Editor package [{PROJECT_DEFAULTS['env']['editor']}]: ").strip()
            or PROJECT_DEFAULTS["env"]["editor"],
            "browser": input(
                f"Browser package [{PROJECT_DEFAULTS['env']['browser']}]: "
            ).strip()
            or PROJECT_DEFAULTS["env"]["browser"],
            "terminal": input(
                f"Terminal package [{PROJECT_DEFAULTS['env']['terminal']}]: "
            ).strip()
            or PROJECT_DEFAULTS["env"]["terminal"],
            "filemanager": input(
                f"File manager package [{PROJECT_DEFAULTS['env']['filemanager']}]: "
            ).strip()
            or PROJECT_DEFAULTS["env"]["filemanager"],
        },
        "enable": [],
        "core_disable": [],
        "hm_enable": [],
    }
    if a["vnc"] and a["desktop"] not in ("hyprland", "sway"):
        warn("wayvnc needs hyprland or sway — turning it off")
        a["vnc"] = False
    if a["nas"]:
        a["enable"].append("services.samba")
    if a["vnc"]:
        a["enable"].append("services.wayvnc")
    a["enable"] += ask_app_list("Optional apps to enable") or []
    a["core_disable"] = ask_app_list("Core apps to disable") or []
    return a


def apply_toggles(universe, enable, disable):
    merged = {}
    for category, apps in universe.items():
        merged[category] = dict(apps)
    for path in enable:
        category, _, app = path.partition(".")
        merged[category][app] = True
    for path in disable:
        category, _, app = path.partition(".")
        merged[category][app] = False
    return merged


def nix_key(key):
    if re.match(r"^[a-zA-Z0-9_]+$", key):
        return key
    escaped = key.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def nix_str(value):
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("${", "\\${")
    return f'"{escaped}"'


def nix_render(value, indent):
    pad = "  " * indent
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        return nix_str(value)
    if value is None:
        return "null"
    if isinstance(value, list):
        if not value:
            return "[]"
        items = "\n".join(f"{pad}  {nix_render(v, indent + 1)}" for v in value)
        return f"[\n{items}\n{pad}]"
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = []
        for key in sorted(value):
            lines.append(f"{pad}  {nix_key(key)} = {nix_render(value[key], indent + 1)};")
        return f"{{\n" + "\n".join(lines) + f"\n{pad}}}"
    raise TypeError(f"cannot render {value!r}")


def render_configuration(a, universes):
    name = a["hostname"]
    enable = list(a.get("enable", []))
    if a.get("nas") and "services.samba" not in enable:
        enable.append("services.samba")
    if a.get("vnc") and "services.wayvnc" not in enable:
        enable.append("services.wayvnc")
    optionals = apply_toggles(universes["optionals"], enable, a.get("disable", []))
    core = apply_toggles(
        universes["core"], a.get("core_enable", []), a.get("core_disable", [])
    )
    home = apply_toggles(universes["home"], a.get("hm_enable", []), a.get("hm_disable", []))

    auto = []
    if a["gpu"] == "virtio" and optionals.get("media", {}).get("davinci-resolve", False):
        optionals["media"]["davinci-resolve"] = False
        auto.append('media."davinci-resolve" = false (virtio GPU cannot run it)')
    if (
        optionals.get("services", {}).get("appimage") is False
        and optionals.get("packaging", {}).get("gearlever", True)
    ):
        optionals["packaging"]["gearlever"] = False
        auto.append("packaging.gearlever = false (gearlever requires appimage)")

    kb = a.get("keyboard") or PROJECT_DEFAULTS["keyboard"]
    if a["gpu"] == "intel":
        displays = {
            "physical": {"eDP-1": {"mode": "1920x1080", "position": "0x0", "scale": 1.0}},
            "virtual": {},
        }
    elif a["gpu"] == "virtio":
        displays = {
            "physical": {},
            "virtual": {"Virtual-1": {"mode": "1920x1080@60", "position": "0x0", "scale": 1.0}},
        }
    else:
        displays = {"physical": {}, "virtual": {}}
    if a.get("vnc"):
        displays["headless"] = {
            "HEADLESS-1": {"mode": "1920x1080@60", "position": "1920x0", "scale": 1.0}
        }
    else:
        displays["headless"] = {}

    env = a.get("env") or PROJECT_DEFAULTS["env"]
    mise = a.get("mise") or PROJECT_DEFAULTS["mise"]
    webapps = a.get("webapps") or {}

    tree = {
        "networking": {"hostname": name},
        "users": {"userName": a["username"]},
        "locale": a.get("locale") or PROJECT_DEFAULTS["locale"],
        "timezone": a.get("timezone") or PROJECT_DEFAULTS["timezone"],
        "theme": {"name": a.get("theme") or PROJECT_DEFAULTS["theme"]},
        "hardware": {
            "gpu": a["gpu"],
            "firmware": a["firmware"],
            **PROJECT_DEFAULTS["hardware_extra"],
        },
        "keyboard": kb,
        "audio": PROJECT_DEFAULTS["audio"],
        "boot": PROJECT_DEFAULTS["boot"],
        "desktop": {"default": a["desktop"]},
        "displayManager": {
            "default": a.get("displayManager") or PROJECT_DEFAULTS["displayManager"],
            "sddm": PROJECT_DEFAULTS["sddm"],
        },
        "displays": displays,
        "gc": PROJECT_DEFAULTS["gc"],
        "mobile": PROJECT_DEFAULTS["mobile"],
        "printing": PROJECT_DEFAULTS["printing"],
        "services": PROJECT_DEFAULTS["services"],
        "env": {key: f"pkgs.{env[key]}" for key in ("editor", "browser", "terminal", "filemanager")},
        "mise": mise,
        "flatpak": {"apps": []},
        "packages": {"extra": []},
        "programs": {"core": core, "optionals": optionals},
    }
    if webapps:
        tree["webapps"] = webapps

    lines = [
        "{",
        "  config,",
        "  pkgs,",
        "  ...",
        "}: {",
        "  imports = [",
        "    ../../modules/nixos/core",
        "    ../../modules/nixos/desktops",
        "    ../../modules/nixos/programs",
        "    ./hardware-configuration.nix",
        "  ];",
        "",
        "  hamra = {",
    ]
    for section in SECTION_ORDER:
        if section == "env":
            lines.append("    env = {")
            for key in ("editor", "browser", "terminal", "filemanager"):
                lines.append(f"      {key} = pkgs.{env[key]};")
            lines.append("    };")
            lines.append("")
            continue
        if section == "webapps" and not webapps:
            continue
        parts = section.split(".")
        node = tree
        for part in parts:
            node = node[part]
        if len(parts) > 1:
            lines.append(f"    {parts[0]}.{'.'.join(parts[1:])} = {nix_render(node, 2)};")
        else:
            lines.append(f"    {nix_key(parts[0])} = {nix_render(node, 2)};")
        lines.append("")
    if lines[-1] == "":
        lines.pop()
    lines += [
        "  };",
        "",
        "  home-manager.users.${config.hamra.users.userName}.hamra.home.programs = "
        + nix_render(home, 1)
        + ";",
        "}",
    ]
    return "\n".join(lines) + "\n", auto


def check_user(username):
    current = getpass.getuser()
    if username != current:
        warn(f"answers user is '{username}' but you are '{current}'")
        if input(f"type '{username}' to confirm anyway: ").strip() != username:
            die("aborted — use a username matching this machine's user")


def check_dirty_targets(hostname):
    r = subprocess.run(
        ["git", "status", "--porcelain", "--", f"hosts/{hostname}"],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    if r.returncode != 0:
        die("not a git repository (git status failed)")
    if r.stdout.strip():
        die(
            "target files have uncommitted changes — hamra-init refuses to risk your work",
            f"git status -- hosts/{hostname} is not clean.\n"
            "Commit or stash them first.",
        )


def check_disk():
    free_gb = shutil.disk_usage(str(REPO)).free / 1024**3
    if free_gb < MIN_FREE_GB:
        die(f"only {free_gb:.1f} GB free — a first build needs more")
    if free_gb < WARN_FREE_GB:
        warn(f"only {free_gb:.1f} GB free — the first build downloads a lot")


def sops_gate(repo):
    r = run(
        ["nix", "develop", "--command", "sops", "-d", "secrets/samba.yaml"],
        cwd=repo,
        capture=True,
        check=False,
    )
    if r.returncode != 0:
        die(
            "the samba secret cannot be decrypted on this machine",
            "The rebuild would fail at activation. Register this machine's key first:\n"
            "  nix develop && ./scripts/setup-nas.sh\n"
            "Or leave the NAS role off.",
        )
    ok("sops secret decrypts on this machine")


def gate(name, cmd, repo):
    print(f"\n── gate: {name} ", flush=True)
    run(cmd, cwd=repo)
    ok(name)


def run_gates(repo, hostname, offer_rebuild):
    gate(
        "format + lint",
        [
            "nix",
            "develop",
            "--command",
            "sh",
            "-c",
            f"alejandra --check hosts/{hostname}/configuration.nix "
            f"&& statix check hosts/{hostname}/configuration.nix "
            f"&& deadnix hosts/{hostname}/configuration.nix",
        ],
        repo,
    )
    gate("nix flake check", ["nix", "flake", "check"], repo)
    gate(
        "nix build toplevel",
        [
            "nix",
            "build",
            "--no-link",
            f".#nixosConfigurations.{hostname}.config.system.build.toplevel",
        ],
        repo,
    )
    if not offer_rebuild:
        return
    print(
        "\nAll gates passed. Next: activate without touching the boot menu.\n"
        "You can roll back with: sudo nixos-rebuild switch --rollback"
    )
    if input("Run 'sudo nixos-rebuild test' now? [y/N]: ").strip().lower() in ("y", "yes"):
        enable_flakes_root()
        run(["sudo", "nixos-rebuild", "test", "--flake", f".#{hostname}"], cwd=repo)
        ok("test activation done")
        print("\nIf the machine looks good, make it the boot default:")
        if input(f"type '{hostname}' to run the switch: ").strip() == hostname:
            run(["sudo", "nixos-rebuild", "switch", "--flake", f".#{hostname}"], cwd=repo)
            ok("switch done — this generation is the new boot default")
        else:
            print("  skipped. Run it yourself with:")
            print(f"  sudo nixos-rebuild switch --flake .#{hostname}")
    else:
        print("  skipped. Run it yourself with:")
        print(f"  sudo nixos-rebuild test --flake .#{hostname}")


def write_host(repo, hostname, configuration, hardware):
    final = repo / "hosts" / hostname
    if final.exists():
        die(f"hosts/{hostname} already exists — write-once rule; nothing was written")
    tmp = Path(tempfile.mkdtemp(dir=repo / "hosts", prefix=f".{hostname}.tmp-"))
    try:
        (tmp / "configuration.nix").write_text(configuration)
        (tmp / "hardware-configuration.nix").write_text(hardware)
        os.replace(tmp, final)
    except BaseException:
        shutil.rmtree(tmp, ignore_errors=True)
        raise
    ok(f"hosts/{hostname}/ created (atomic)")


def print_git_hint(hostname):
    print(
        "\nWhen you are happy with the result, commit it yourself:\n"
        f"  git add hosts/{hostname}\n"
        f'  git commit -m "feat(hosts): add {hostname} (hamra-init)"'
    )


def ensure_flakes_user():
    """Enable nix-command + flakes for the current user (idempotent, no sudo).

    A fresh NixOS install ships without them, and every nix call the engine
    makes needs them. The one-time bootstrap flag on the launch command got
    us here; from now on the config is persistent.
    """
    conf = Path.home() / ".config/nix/nix.conf"
    conf.parent.mkdir(parents=True, exist_ok=True)
    existing = conf.read_text() if conf.is_file() else ""
    if "experimental-features" not in existing:
        with conf.open("a") as f:
            f.write("experimental-features = nix-command flakes\n")
        ok(f"enabled flakes for the user ({conf})")
    if "nix-command flakes" not in existing and "experimental-features" in existing:
        warn(
            f"{conf} sets experimental-features without nix-command flakes — "
            "the bootstrap flag will be needed for now"
        )


def offer_etc_nixos_symlink(repo):
    """One-time /etc/nixos setup: back up the installer's config, symlink the checkout.

    Needs sudo, so it is always announced and confirmed by typing the answer.
    """
    target = Path("/etc/nixos")
    if target.is_symlink():
        if target.resolve() == repo.resolve():
            return
        warn(f"/etc/nixos symlinks to {target.resolve()} (not this checkout)")
        return
    if target.exists():
        backup = Path("/etc/nixos.pre-hamra")
        print(
            "\nOne-time setup (runs with sudo): back up the installer's /etc/nixos\n"
            f"to {backup} and symlink this checkout in its place. This is what\n"
            "makes plain `nixos-rebuild` and setup-nas find the repository."
        )
        if input("Do it now? [y/N]: ").strip().lower() not in ("y", "yes"):
            print("  skipped — plain nixos-rebuild will not find the repository until done")
            return
        if backup.exists():
            die(f"{backup} already exists — refusing to overwrite it")
        run(["sudo", "mv", str(target), str(backup)])
    else:
        print("\nOne-time setup (runs with sudo): symlink this checkout to /etc/nixos.")
        if input("Do it now? [y/N]: ").strip().lower() not in ("y", "yes"):
            print("  skipped — plain nixos-rebuild will not find the repository until done")
            return
    run(["sudo", "ln", "-s", str(repo), str(target)])
    ok(f"/etc/nixos -> {repo}")


def enable_flakes_root():
    """Enable flakes for root, piggybacked on the confirmed rebuild step."""
    run(
        [
            "sudo",
            "sh",
            "-c",
            "mkdir -p /root/.config/nix; "
            "grep -q '^experimental-features' /root/.config/nix/nix.conf 2>/dev/null "
            "|| echo 'experimental-features = nix-command flakes' "
            ">> /root/.config/nix/nix.conf",
        ]
    )
    ok("flakes enabled for root (one-time)")


def load_universes(repo):
    return {
        "core": toggle_universe(repo, "core"),
        "optionals": toggle_universe(repo, "optionals"),
        "home": home_universe(repo),
    }


def cmd_check(repo, enums):
    print("hamra-init --check (read-only audit)")
    check_disk()
    existing = scanned_hosts(repo)
    ok(f"repo: {repo}")
    ok(f"hosts: {', '.join(existing) or '(none)'}")
    universes = load_universes(repo)
    total = sum(len(v) for universe in universes.values() for v in universe.values())
    ok(f"toggle universes reachable: {total} toggles")
    key = Path.home() / ".config/sops/age/keys.txt"
    if key.is_file():
        ok("sops editing key present")
    else:
        warn("no sops editing key (only needed to create/reset NAS passwords)")
    nixconf = Path.home() / ".config/nix/nix.conf"
    if nixconf.is_file() and "nix-command" in nixconf.read_text():
        ok("flakes enabled for the user")
    else:
        warn("user nix.conf lacks flakes (the wizard enables it; harmless when the system already provides them)")
    etsymlink = Path("/etc/nixos")
    if etsymlink.is_symlink() and etsymlink.resolve() == repo.resolve():
        ok("/etc/nixos symlinks to this checkout")
    elif etsymlink.is_symlink():
        warn(f"/etc/nixos symlinks to {etsymlink.resolve()} (not this checkout)")
    elif etsymlink.exists():
        warn("/etc/nixos is the installer's copy (the wizard offers the backup + symlink)")
    else:
        warn("/etc/nixos does not exist (the wizard can create the symlink)")
    print("\nEnvironment ready for hamra-init.")


def main():
    p = argparse.ArgumentParser(description="Generate and validate a Hamra host.")
    p.add_argument("--answers", help="JSON file with the machine answers (non-interactive)")
    p.add_argument("--dry-run", action="store_true", help="print the files; write nothing")
    p.add_argument(
        "--render-only",
        action="store_true",
        help="print only configuration.nix to stdout (golden-test mode; no hardware, no writes)",
    )
    p.add_argument("--check", action="store_true", help="read-only environment audit")
    p.add_argument("--gates-only", metavar="HOST", help="re-run the validation gates for an existing host")
    p.add_argument(
        "--disable",
        default="",
        help="comma-separated apps to disable, e.g. gui.firefox,media.kodi",
    )
    p.add_argument(
        "--enable",
        default="",
        help="comma-separated apps to enable, e.g. gui.firefox,media.kodi",
    )
    args = p.parse_args()

    global REPO
    REPO = repo_root()

    if args.check:
        cmd_check(REPO, load_enums(REPO))
        return

    if args.gates_only:
        if args.gates_only not in scanned_hosts(REPO):
            die(f"hosts/{args.gates_only} does not exist")
        run_gates(REPO, args.gates_only, offer_rebuild=True)
        return

    if not args.render_only and not args.dry_run:
        ensure_flakes_user()

    enums = load_enums(REPO)
    existing = scanned_hosts(REPO)
    universes = load_universes(REPO)

    if args.answers:
        a = parse_answers_file(args.answers)
        if args.disable:
            a["disable"] = a.get("disable", []) + [
                s.strip() for s in args.disable.split(",") if s.strip()
            ]
        if args.enable:
            a["enable"] = a.get("enable", []) + [
                s.strip() for s in args.enable.split(",") if s.strip()
            ]
        validate_answers(a, enums, existing, universes)
    else:
        a = collect_answers(enums, existing, args)
        validate_answers(a, enums, existing, universes)

    configuration, auto = render_configuration(a, universes)

    if args.render_only:
        print(configuration, end="")
        return

    hardware, hw_source = hardware_config_source(REPO)

    print(f"\nhamra-init — hosts/{a['hostname']}")
    info(f"hardware from: {hw_source}")
    for note in auto:
        info(f"auto-adjusted: {note}")

    if args.dry_run:
        print("\n===== hosts/%s/configuration.nix =====" % a["hostname"])
        print(configuration, end="")
        print("\n===== hosts/%s/hardware-configuration.nix =====" % a["hostname"])
        print(hardware, end="")
        print("\n(dry-run: nothing was written, gates not run)")
        return

    offer_etc_nixos_symlink(REPO)
    check_dirty_targets(a["hostname"])
    check_disk()
    check_user(a["username"])
    if a.get("nas"):
        sops_gate(REPO)

    write_host(REPO, a["hostname"], configuration, hardware)
    run_gates(REPO, a["hostname"], offer_rebuild=True)
    print_git_hint(a["hostname"])


if __name__ == "__main__":
    main()
