#!/usr/bin/env python3
"""hamra-init — generate a Hamra host from answers, validate it, guide the rebuild.

Design contract (see CONTRIBUTING.md):
  - Pure headless engine: --answers + --dry-run are fully testable (golden tests).
  - Write-once: an existing hosts/<name> is never overwritten; re-run shows how to diff.
  - Atomic writes: the host directory is created via temp-dir + rename, never half-written.
  - The installer only CREATES files and runs read-only validation. It never runs gc,
    never stages or commits, and only runs nixos-rebuild after typed confirmation.
  - Enums come from a single source (modules/lib/enums.nix), the same file the
    assertions use, so the interface can never drift from the validation.

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
MIN_FREE_GB = 5
WARN_FREE_GB = 15


def die(msg, hint=""):
    print(f"hamra-init: {msg}", file=sys.stderr)
    if hint:
        print(hint, file=sys.stderr)
    sys.exit(1)


def info(msg):
    print(f"  {msg}")


def ok(msg):
    print(f"  ✓ {msg}")


def warn(msg):
    print(f"  ⚠ {msg}")


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
        e.name
        for e in hosts.iterdir()
        if e.is_dir() and e.name not in ("common", "profiles") and not e.name.startswith(".")
    )


def profiles(repo):
    pdir = repo / "hosts/profiles"
    return sorted(e.name for e in pdir.iterdir() if e.is_dir()) if pdir.is_dir() else []


def optionals_catalog(repo, sample_host):
    r = run(
        [
            "nix",
            "eval",
            "--json",
            f".#nixosConfigurations.{sample_host}.config.hamra.programs.optionals",
        ],
        cwd=repo,
        capture=True,
    )
    return json.loads(r.stdout)


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
        if raw in ("common", "profiles"):
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
    if not ask_yes_no("Custom keyboard for this machine? (default is the base br/abnt2)"):
        return None
    keymap = input("  keymap (e.g. us, br): ").strip() or "us"
    variant = input("  xkbVariant (e.g. intl, abnt2 — empty for none): ").strip()
    return {"keymap": keymap, "xkbVariant": variant} if variant else {"keymap": keymap}


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


def render_configuration(a):
    name = a["hostname"]
    profile = a["profile"]

    overrides = {}
    for path in a.get("disable", []):
        category, _, app = path.partition(".")
        overrides.setdefault(category, {})[app] = False
    if a.get("nas"):
        overrides.setdefault("services", {})["samba"] = True
    if a.get("vnc"):
        overrides.setdefault("services", {})["wayvnc"] = True

    auto = []
    if a["gpu"] == "virtio" and overrides.get("media", {}).get("davinci-resolve", True):
        overrides.setdefault("media", {})["davinci-resolve"] = False
        auto.append("media.\"davinci-resolve\" = false (virtio GPU cannot run it)")
    if (
        overrides.get("services", {}).get("appimage") is False
        and overrides.get("packaging", {}).get("gearlever", True)
    ):
        overrides.setdefault("packaging", {})["gearlever"] = False
        auto.append("packaging.gearlever = false (gearlever requires appimage)")

    lines = [
        "_: {",
        "  imports = [",
        "    ../../modules/nixos/core",
        "    ../../modules/nixos/desktops",
        "    ../../modules/nixos/programs",
        "    ../common",
        f"    ../profiles/{profile}",
        "    ./hardware-configuration.nix",
        "  ];",
        "",
        "  hamra = {",
        f'    networking.hostname = "{name}";',
        "",
        "    hardware = {",
        f'      gpu = "{a["gpu"]}";',
        f'      firmware = "{a["firmware"]}";',
        "    };",
    ]

    kb = a.get("keyboard")
    if kb:
        lines += [
            "",
            "    keyboard = {",
            f'      keymap = "{kb["keymap"]}";',
        ]
        if kb.get("xkbVariant"):
            lines.append(f'      xkbVariant = "{kb["xkbVariant"]}";')
        lines.append("    };")

    lines += [
        "",
        f'    desktop.default = "{a["desktop"]}";',
    ]

    if overrides:
        lines += ["", "    programs.optionals = {"]
        for category in sorted(overrides):
            lines.append(f"      {category} = {{")
            for app in sorted(overrides[category]):
                value = "true" if overrides[category][app] else "false"
                key = app if re.match(r"^[a-zA-Z0-9_]+$", app) else f'"{app}"'
                lines.append(f"        {key} = {value};")
            lines.append("      };")
        lines.append("    };")

    lines += [
        "  };",
        "}",
    ]
    return "\n".join(lines) + "\n", auto


def validate_answers(a, enums, existing_hosts, catalog):
    required = {
        "hostname",
        "gpu",
        "firmware",
        "desktop",
        "profile",
        "nas",
        "vnc",
    }
    missing = required - set(a)
    if missing:
        die(f"answers file is missing keys: {', '.join(sorted(missing))}")
    if not HOSTNAME_RE.match(a["hostname"]):
        die(f"invalid hostname '{a['hostname']}' (letters, numbers, hyphens)")
    if a["hostname"] in ("common", "profiles"):
        die("'common' and 'profiles' are reserved names")
    if a["hostname"] in existing_hosts:
        die(f"hosts/{a['hostname']} already exists — hamra-init never overwrites (write-once)")
    if a["gpu"] not in enums["gpus"]:
        die(f"invalid gpu '{a['gpu']}' — use one of: {' | '.join(enums['gpus'])}")
    if a["firmware"] not in enums["firmware"]:
        die(f"invalid firmware '{a['firmware']}' — use one of: {' | '.join(enums['firmware'])}")
    if a["desktop"] not in enums["desktops"]:
        die(f"invalid desktop '{a['desktop']}' — use one of: {' | '.join(enums['desktops'])}")
    if a["profile"] not in profiles(REPO):
        die(f"profile '{a['profile']}' not found under hosts/profiles/")
    if a.get("vnc") and a["desktop"] not in ("hyprland", "sway"):
        die("wayvnc requires desktop hyprland or sway (assertion rule)")
    for path in a.get("disable", []):
        category, _, app = path.partition(".")
        if category not in catalog or app not in catalog.get(category, {}):
            die(f"unknown app to disable: '{path}' — not in the optionals catalog")
    kb = a.get("keyboard")
    if kb is not None and not kb.get("keymap"):
        die("keyboard.keymap cannot be empty when keyboard is set")


def collect_answers(enums, existing_hosts, args):
    pro = profiles(REPO)
    if args.profile:
        if args.profile not in pro:
            die(f"profile '{args.profile}' not found; available: {' | '.join(pro)}")
        profile = args.profile
    else:
        profile = pro[0] if len(pro) == 1 else ask_enum("Profile", pro, pro[0])

    detected_gpu = detect_gpu()
    gpu_default = detected_gpu or "intel"
    detected_fw = detect_firmware()

    a = {
        "hostname": ask_hostname(existing_hosts),
        "gpu": ask_enum("GPU", enums["gpus"], gpu_default),
        "firmware": ask_enum("Firmware", enums["firmware"], detected_fw),
        "desktop": ask_enum("Desktop", enums["desktops"], "hyprland"),
        "profile": profile,
        "nas": ask_yes_no("Is this machine the NAS (Samba)?"),
        "vnc": ask_yes_no("Run the wayvnc server here?"),
        "keyboard": ask_keyboard(),
        "disable": [],
    }
    if a["vnc"] and a["desktop"] not in ("hyprland", "sway"):
        warn("wayvnc needs hyprland or sway — turning it off")
        a["vnc"] = False
    raw = input(
        "Apps to disable on this machine (comma-separated, e.g. gui.firefox,media.kodi; "
        "empty = keep everything from the profile): "
    ).strip()
    if raw:
        a["disable"] = [s.strip() for s in raw.split(",") if s.strip()]
    return a


def check_user(profile):
    identity = REPO / "hosts/profiles" / profile / "identity.nix"
    m = re.search(r'userName\s*=\s*"([^"]+)"', identity.read_text())
    if not m:
        return
    profile_user = m.group(1)
    current = getpass.getuser()
    if profile_user != current:
        warn(f"profile user is '{profile_user}' but you are '{current}'")
        if input(f"type '{profile_user}' to confirm anyway: ").strip() != profile_user:
            die("aborted — pick a profile whose userName matches this machine's user")


def check_dirty_targets(hostname):
    r = subprocess.run(
        ["git", "status", "--porcelain", "--", f"hosts/{hostname}", "flake/hosts.nix"],
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


def sops_gate(repo, profile_user_hint):
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


def cmd_check(repo, enums):
    print("hamra-init --check (read-only audit)")
    check_disk()
    existing = scanned_hosts(repo)
    pro = profiles(repo)
    ok(f"repo: {repo}")
    ok(f"hosts: {', '.join(existing) or '(none)'}")
    ok(f"profiles: {', '.join(pro) or '(none)'}")
    if not existing:
        die("no hosts to sample the optionals catalog from")
    catalog = optionals_catalog(repo, existing[0])
    total = sum(len(v) for v in catalog.values())
    ok(f"optionals catalog reachable: {total} apps in {len(catalog)} categories")
    key = Path.home() / ".config/sops/age/keys.txt"
    if key.is_file():
        ok("sops editing key present")
    else:
        warn("no sops editing key (only needed to create/reset NAS passwords)")
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
    p.add_argument("--profile", help="profile under hosts/profiles/ (default: the only one)")
    p.add_argument(
        "--disable",
        default="",
        help="comma-separated apps to disable, e.g. gui.firefox,media.kodi",
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

    enums = load_enums(REPO)
    existing = scanned_hosts(REPO)

    if args.answers:
        a = parse_answers_file(args.answers)
        if args.disable:
            a["disable"] = a.get("disable", []) + [
                s.strip() for s in args.disable.split(",") if s.strip()
            ]
        if not existing:
            die("no hosts to sample the optionals catalog from")
        validate_answers(a, enums, existing, optionals_catalog(REPO, existing[0]))
    else:
        a = collect_answers(enums, existing, args)
        if not existing:
            die("no hosts to sample the optionals catalog from")
        validate_answers(a, enums, existing, optionals_catalog(REPO, existing[0]))

    configuration, auto = render_configuration(a)

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

    check_dirty_targets(a["hostname"])
    check_disk()
    check_user(a["profile"])
    if a.get("nas"):
        sops_gate(REPO, None)

    write_host(REPO, a["hostname"], configuration, hardware)
    run_gates(REPO, a["hostname"], offer_rebuild=True)
    print_git_hint(a["hostname"])


if __name__ == "__main__":
    main()
