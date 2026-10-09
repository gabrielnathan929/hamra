#!/usr/bin/env python3
"""hamra-setup — graphical installer for Hamra (GTK4 + libadwaita).

A single-window GNOME-style application with pages for each step.
Thin layer over the hamra-init engine.

Packaging note: the engine file lives next to this script in the nix store.
The GUI finds it there first, then falls back to the repo checkout.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Adw, GLib, Gtk, Pango

_HERE = Path(__file__).resolve().parent
REPO = Path(os.environ.get("HAMRA_REPO", os.getcwd()))
_ENGINE_BUNDLED = _HERE / "hamra-init.py"
ENGINE = (
    _ENGINE_BUNDLED if _ENGINE_BUNDLED.is_file() else REPO / "scripts/hamra-init.py"
)
HOSTNAME_RE = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9-]*$")


def sh(args):
    r = subprocess.run(args, capture_output=True, text=True)
    return r.returncode, r.stdout.strip(), r.stderr.strip()


def read_json(args):
    _, out, err = sh(args)
    if err:
        print(err, file=sys.stderr)
        sys.exit(1)
    return json.loads(out)


def get_enums():
    return read_json(
        ["nix", "eval", "--json", "--file", str(REPO / "modules/lib/enums.nix")]
    )


def get_existing_hosts():
    try:
        data = read_json(
            [
                "nix",
                "eval",
                "--json",
                "--file",
                str(REPO / "flake/hosts.nix"),
                "--apply",
                "x: builtins.attrNames x",
            ]
        )
        return data
    except (SystemExit, json.JSONDecodeError):
        return []


def get_catalog(sample_host):
    if not sample_host:
        return {}
    try:
        return read_json(
            [
                "nix",
                "eval",
                "--json",
                f".#nixosConfigurations.{sample_host}.config.hamra.programs.optionals",
            ]
        )
    except (SystemExit, json.JSONDecodeError):
        return {}


def get_profile_apps():
    apps_file = REPO / "hosts/profiles/gabrielnathan/apps.nix"
    if not apps_file.is_file():
        return []
    apps = set()
    for line in apps_file.read_text().splitlines():
        m = re.match(r'\s+"?([a-zA-Z0-9_-]+)"?\s*=\s*true', line)
        if m:
            apps.add(m.group(1))
    return sorted(apps)


class SetupWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_default_size(720, 640)
        self.set_title("Hamra Setup")
        self.answers = {}
        self.existing_hosts = []
        self.enums = {}
        self.proc = None
        self.page = 0

        self.load_data()

        header = Adw.HeaderBar()

        self.prev_btn = Gtk.Button(label="Back", sensitive=False)
        self.prev_btn.connect("clicked", self.on_prev)
        self.next_btn = Gtk.Button(label="Continue", css_classes=["suggested-action"])
        self.next_btn.connect("clicked", self.on_next)

        header.pack_start(self.prev_btn)
        header.pack_end(self.next_btn)

        self.carousel = Adw.Carousel()
        self.carousel.set_interactive(False)
        self.carousel.connect("page-changed", self.on_page_changed)

        self.build_identity_page()
        self.build_roles_page()
        self.build_apps_page()
        self.build_progress_page()

        for page in [
            self.identity_page,
            self.roles_page,
            self.apps_page,
            self.progress_page,
        ]:
            scroll = Gtk.ScrolledWindow()
            scroll.set_child(page)
            scroll.set_vexpand(True)
            self.carousel.append(scroll)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        root.append(header)
        root.append(self.carousel)
        self.set_content(root)

    def load_data(self):
        self.enums = get_enums()
        self.existing_hosts = get_existing_hosts()
        sample = sorted(self.existing_hosts)[0] if self.existing_hosts else None
        self.catalog = get_catalog(sample)
        self.profile_apps = get_profile_apps()

    # ──────────────────────────────────────────────────────────── pages

    def build_identity_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        page.set_margin_top(32)
        page.set_margin_bottom(32)
        page.set_margin_start(32)
        page.set_margin_end(32)

        title = Gtk.Label(label="New machine")
        title.add_css_class("title-2")
        page.append(title)

        subtitle = Gtk.Label(
            label="Name the machine and pick its hardware profile.\n"
            "The GPU and firmware are detected from the running system.",
            wrap=True, xalign=0,
            css_classes=["dimmed"],
        )
        page.append(subtitle)

        group = Adw.PreferencesGroup()
        self.name_entry = Adw.EntryRow(title="Machine name")
        self.name_entry.set_text("my-pc")
        self.name_entry.connect("changed", self.validate_name)
        self.name_error = Gtk.Label(css_classes=["error"], xalign=0, visible=False)
        group.add(self.name_entry)
        group.add(self.name_error)

        self.gpu_combo = self.make_combo("GPU", self.enums.get("gpus", []))
        group.add(self.gpu_combo)

        self.fw_combo = self.make_combo(
            "Firmware",
            self.enums.get("firmware", []),
            default="uefi" if os.path.isdir("/sys/firmware/efi") else "bios",
        )
        group.add(self.fw_combo)

        self.desk_combo = self.make_combo(
            "Desktop", self.enums.get("desktops", [])
        )
        group.add(self.desk_combo)

        page.append(group)
        self.identity_page = page

    def build_roles_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        page.set_margin_top(32)
        page.set_margin_bottom(32)
        page.set_margin_start(32)
        page.set_margin_end(32)

        title = Gtk.Label(label="Roles & keyboard")
        title.add_css_class("title-2")
        page.append(title)

        subtitle = Gtk.Label(
            label="Roles say what this machine IS, not what you like.\n"
            "Leave both off if unsure.",
            wrap=True, xalign=0,
            css_classes=["dimmed"],
        )
        page.append(subtitle)

        group = Adw.PreferencesGroup()
        self.nas_switch = Adw.SwitchRow(
            title="NAS (Samba)",
            subtitle="Shares shared/, games/ and backups/ over the network",
        )
        self.vnc_switch = Adw.SwitchRow(
            title="WayVNC server",
            subtitle="Remote access to this machine's screen",
        )
        group.add(self.nas_switch)
        group.add(self.vnc_switch)

        self.desk_combo.connect("notify::selected", self.update_vnc)

        kb_group = Adw.PreferencesGroup(title="Keyboard")
        self.kb_switch = Adw.SwitchRow(
            title="Custom layout",
            subtitle="Off keeps the base default (br/abnt2)",
        )
        self.kb_keymap = Adw.EntryRow(title="keymap (e.g. us, br)")
        self.kb_variant = Adw.EntryRow(title="xkbVariant (e.g. intl, abnt2)")
        self.kb_keymap.set_visible(False)
        self.kb_variant.set_visible(False)
        self.kb_switch.connect("notify::active", self.on_kb_toggle)
        kb_group.add(self.kb_switch)
        kb_group.add(self.kb_keymap)
        kb_group.add(self.kb_variant)

        page.append(group)
        page.append(kb_group)
        self.roles_page = page

    def build_apps_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)
        page.set_margin_top(32)
        page.set_margin_bottom(32)
        page.set_margin_start(32)
        page.set_margin_end(32)

        title = Gtk.Label(label="Apps")
        title.add_css_class("title-2")
        page.append(title)

        subtitle = Gtk.Label(
            label="Everything below comes from the personal profile.\n"
            "Switch off what this machine should NOT have.\n"
            "The installer also auto-applies assertion rules.",
            wrap=True, xalign=0,
            css_classes=["dimmed"],
        )
        page.append(subtitle)

        group = Adw.PreferencesGroup()
        self.app_switches = {}
        for app in self.profile_apps:
            row = Adw.SwitchRow(title=app)
            row.set_active(True)
            self.app_switches[app] = row
            group.add(row)

        page.append(group)
        self.apps_page = page

    def build_progress_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        page.set_margin_top(32)
        page.set_margin_bottom(32)
        page.set_margin_start(32)
        page.set_margin_end(32)

        self.status_label = Gtk.Label(
            label="Ready to generate.\n"
            "Press Continue to create the host and run validation.",
            wrap=True, xalign=0,
        )
        page.append(self.status_label)

        scrolled = Gtk.ScrolledWindow()
        self.output_view = Gtk.TextView()
        self.output_view.set_editable(False)
        self.output_view.set_monospace(True)
        self.output_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        scrolled.set_child(self.output_view)
        scrolled.set_vexpand(True)
        page.append(scrolled)

        self.test_btn = Gtk.Button(
            label="Run rebuild test (sudo)", sensitive=False
        )
        self.test_btn.connect("clicked", self.on_test)

        self.switch_btn = Gtk.Button(
            label="Make boot default (sudo)",
            sensitive=False,
            css_classes=["destructive-action"],
        )
        self.switch_btn.connect("clicked", self.on_switch)

        btn_box = Gtk.Box(spacing=12)
        btn_box.append(self.test_btn)
        btn_box.append(self.switch_btn)
        page.append(btn_box)

        page.append(
            Gtk.Label(
                label="The installer never commits. Rollback: sudo nixos-rebuild switch --rollback",
                css_classes=["caption"], xalign=0,
            )
        )
        self.progress_page = page

    # ──────────────────────────────────────────────────────────── helpers

    def make_combo(self, title, values, default=None):
        row = Adw.ComboRow(title=title)
        model = Gtk.StringList()
        for v in values:
            model.append(v)
        row.set_model(model)
        if default and default in values:
            idx = values.index(default)
            row.set_selected(idx)
        return row

    def combo_value(self, row):
        item = row.get_selected_item()
        return item.get_string() if item else ""

    def validate_name(self, entry):
        name = entry.get_text().strip()
        if not name:
            self.name_error.set_visible(False)
            return
        if not HOSTNAME_RE.match(name):
            self.name_error.set_text("Use letters, numbers and hyphens only.")
            self.name_error.set_visible(True)
        elif name in ("common", "profiles"):
            self.name_error.set_text("'common' and 'profiles' are reserved.")
            self.name_error.set_visible(True)
        elif name in self.existing_hosts:
            self.name_error.set_text(
                f"hosts/{name} already exists — the installer never overwrites."
            )
            self.name_error.set_visible(True)
        else:
            self.name_error.set_visible(False)

    def update_vnc(self, *_):
        desktop = self.combo_value(self.desk_combo)
        allowed = desktop in ("hyprland", "sway")
        self.vnc_switch.set_sensitive(allowed)
        if not allowed and self.vnc_switch.get_active():
            self.vnc_switch.set_active(False)

    def on_kb_toggle(self, row, *_):
        active = row.get_active()
        self.kb_keymap.set_visible(active)
        self.kb_variant.set_visible(active)

    def on_page_changed(self, carousel, index):
        self.page = index
        self.prev_btn.set_sensitive(index > 0)
        self.next_btn.set_label("Continue" if index < 3 else "Generate")
        if index == 2:
            self.next_btn.add_css_class("suggested-action")
        if index == 3:
            self.next_btn.set_label("Generate")
            self.next_btn.get_style_context().add_class("suggested-action")

    def on_prev(self, *_):
        if self.page > 0:
            self.carousel.scroll_to(self.carousel.get_nth_page(self.page - 1), True)

    def on_next(self, *_):
        if self.page < 3:
            self.carousel.scroll_to(self.carousel.get_nth_page(self.page + 1), True)
        elif self.page == 3:
            self.generate()

    # ──────────────────────────────────────────────────────────── generate

    def collect(self):
        desktop = self.combo_value(self.desk_combo)
        vnc = self.vnc_switch.get_active()
        if vnc and desktop not in ("hyprland", "sway"):
            vnc = False
        keyboard = None
        if self.kb_switch.get_active():
            keyboard = {
                "keymap": self.kb_keymap.get_text().strip() or "us",
                "xkbVariant": self.kb_variant.get_text().strip(),
            }
        disabled = [
            app for app, row in self.app_switches.items() if not row.get_active()
        ]
        return {
            "hostname": self.name_entry.get_text().strip(),
            "gpu": self.combo_value(self.gpu_combo),
            "firmware": self.combo_value(self.fw_combo),
            "desktop": desktop,
            "profile": "gabrielnathan",
            "nas": self.nas_switch.get_active(),
            "vnc": vnc,
            "keyboard": keyboard,
            "disable": disabled,
        }

    def generate(self):
        self.answers = self.collect()
        self.next_btn.set_sensitive(False)
        self.status_label.set_text(f"Generating hosts/{self.answers['hostname']}…")

        answers_file = _HERE / ".gui-answers.json"
        answers_file.write_text(json.dumps(self.answers, indent=2))

        buf = self.output_view.get_buffer()
        buf.set_text("")
        self.proc = subprocess.Popen(
            [sys.executable, str(ENGINE), "--answers", str(answers_file)],
            cwd=REPO,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        GLib.io_add_watch(
            self.proc.stdout, GLib.IO_IN | GLib.IO_HUP, self.on_engine_output
        )

    def append_output(self, text):
        buf = self.output_view.get_buffer()
        end = buf.get_end_iter()
        buf.insert(end, text)
        adj = self.output_view.get_vadjustment()
        adj.set_value(adj.get_upper())

    def on_engine_output(self, source, condition):
        if condition & GLib.IO_IN:
            line = source.readline()
            if line:
                self.append_output(line)
        if condition & GLib.IO_HUP or (self.proc.poll() is not None):
            code = self.proc.wait()
            self.append_output(f"\n[exit: {code}]\n")
            if code == 0:
                self.status_label.set_text(
                    "All gates passed.\n"
                    "Run the rebuild test below, or manually:\n"
                    f"  sudo nixos-rebuild test --flake .#{self.answers['hostname']}"
                )
                self.test_btn.set_sensitive(True)
            else:
                self.status_label.set_text(
                    "The engine failed. Check the output above.\n"
                    "Fix the answers and try again."
                )
                self.next_btn.set_sensitive(True)
            return False
        return True

    def on_test(self, *_):
        hostname = self.answers["hostname"]
        self.test_btn.set_sensitive(False)
        self.status_label.set_text("Running rebuild test…")
        self.append_output(f"\n$ sudo nixos-rebuild test --flake .#{hostname}\n")

        subprocess.run(
            [
                "sudo", "sh", "-c",
                "mkdir -p /root/.config/nix; "
                "grep -q '^experimental-features' /root/.config/nix/nix.conf 2>/dev/null "
                "|| echo 'experimental-features = nix-command flakes' "
                ">> /root/.config/nix/nix.conf",
            ],
            capture_output=True,
        )

        self.subproc = subprocess.Popen(
            ["sudo", "nixos-rebuild", "test", "--flake", f".#{hostname}"],
            cwd=REPO,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        GLib.io_add_watch(
            self.subproc.stdout, GLib.IO_IN | GLib.IO_HUP, self.on_sub_output
        )

    def on_sub_output(self, source, condition):
        if condition & GLib.IO_IN:
            line = source.readline()
            if line:
                self.append_output(line)
        if condition & GLib.IO_HUP or (self.subproc.poll() is not None):
            code = self.subproc.wait()
            self.append_output(f"\n[exit: {code}]\n")
            if code == 0:
                self.status_label.set_text(
                    "Test passed!\n"
                    "To make this the boot default:\n"
                    f"  sudo nixos-rebuild switch --flake .#{self.answers['hostname']}\n\n"
                    "Commit when ready:\n"
                    f"  git add hosts/{self.answers['hostname']}"
                )
                self.switch_btn.set_sensitive(True)
            else:
                self.status_label.set_text("Rebuild test failed. Check output above.")
                self.test_btn.set_sensitive(True)
            return False
        return True

    def on_switch(self, *_):
        hostname = self.answers["hostname"]
        self.switch_btn.set_sensitive(False)
        self.status_label.set_text("Switching…")
        self.append_output(f"\n$ sudo nixos-rebuild switch --flake .#{hostname}\n")

        self.subproc = subprocess.Popen(
            ["sudo", "nixos-rebuild", "switch", "--flake", f".#{hostname}"],
            cwd=REPO,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        GLib.io_add_watch(
            self.subproc.stdout, GLib.IO_IN | GLib.IO_HUP, self.on_sub_output
        )


class SetupApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="dev.hamra.setup")

    def do_activate(self):
        win = SetupWindow(self)
        win.present()


if __name__ == "__main__":
    if not (REPO / "flake.nix").is_file():
        print(f"repository not found at {REPO}", file=sys.stderr)
        print("Run from the Hamra checkout, or set HAMRA_REPO.", file=sys.stderr)
        sys.exit(1)
    app = SetupApp()
    app.run(sys.argv)
