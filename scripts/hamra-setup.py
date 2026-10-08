#!/usr/bin/env python3
"""hamra-setup — the graphical face of hamra-init.

A GTK4 + libadwaita wizard (GNOME-style app) that collects the machine
answers with dropdowns, switches and app checkboxes, then drives the
hamra-init engine with --answers and streams the validation gates.

Design contract (same as the engine, see scripts/hamra-init.py):
  - thin layer over the engine — all decisions, gates and safety rules live
    in the engine; this app only collects and displays
  - enums come from the single source (modules/lib/enums.nix)
  - the app catalog comes from the same optionals eval the engine uses
  - sudo actions (rebuild) only run after an explicit button click, and the
    app never commits anything
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

from gi.repository import Adw, GLib, Gtk  # noqa: E402

REPO = Path(os.environ.get("HAMRA_REPO", os.getcwd()))
_HERE = Path(__file__).resolve().parent
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


class SetupApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id="dev.hamra.setup")
        self.answers = {}
        self.existing_hosts = []
        self.enums = {}
        self.catalog = {}
        self.proc = None
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        self.enums = read_json(
            ["nix", "eval", "--json", "--file", str(REPO / "modules/lib/enums.nix")]
        )
        hosts_cmd = [
            "nix",
            "eval",
            "--json",
            "--file",
            str(REPO / "flake/hosts.nix"),
            "--apply",
            "x: builtins.attrNames x",
        ]
        try:
            self.existing_hosts = read_json(hosts_cmd)
        except SystemExit:
            self.existing_hosts = []
        sample = sorted(self.existing_hosts)[0] if self.existing_hosts else None
        self.catalog = (
            read_json(
                [
                    "nix",
                    "eval",
                    "--json",
                    f".#nixosConfigurations.{sample}.config.hamra.programs.optionals",
                ]
            )
            if sample
            else {}
        )

        self.win = Adw.ApplicationWindow(application=app)
        self.win.set_default_size(780, 640)
        self.win.set_title("Hamra Setup")

        header = Adw.HeaderBar()
        header.set_title_widget(
            Gtk.Label(label="New machine", css_classes=["heading"])
        )

        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.switcher = Gtk.StackSwitcher(stack=self.stack)
        header.pack_start(self.switcher)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        root.append(header)
        root.append(self.stack)

        self.build_machine_page()
        self.build_apps_page()
        self.build_progress_page()
        self.stack.add_titled(self.machine_page, "machine", "Machine")
        self.stack.add_titled(self.apps_page, "apps", "Apps")
        self.stack.add_titled(self.progress_page, "progress", "Generate")

        self.win.set_content(root)
        self.win.present()

    # ------------------------------------------------------------------ pages

    def build_machine_page(self):
        page = Adw.PreferencesPage()
        group = Adw.PreferencesGroup(title="Identity")

        self.name_row = Adw.EntryRow(title="Machine name")
        self.name_row.set_text("my-pc")
        group.add(self.name_row)

        gpu_row = Adw.ComboRow(title="GPU")
        gpu_model = Gtk.StringList()
        for value in self.enums.get("gpus", []):
            gpu_model.append(value)
        gpu_row.set_model(gpu_model)
        self.gpu_row = gpu_row
        group.add(gpu_row)

        fw_row = Adw.ComboRow(title="Firmware")
        fw_model = Gtk.StringList()
        for value in self.enums.get("firmware", []):
            fw_model.append(value)
        fw_row.set_model(fw_model)
        self.fw_row = fw_row
        group.add(fw_row)

        desk_row = Adw.ComboRow(title="Desktop")
        desk_model = Gtk.StringList()
        for value in self.enums.get("desktops", []):
            desk_model.append(value)
        desk_row.set_model(desk_model)
        self.desk_row = desk_row
        group.add(desk_row)

        roles = Adw.PreferencesGroup(title="Host roles")
        self.nas_row = Adw.SwitchRow(
            title="NAS (Samba)",
            subtitle="Shares shared/, games/ and backups/ over the network",
        )
        self.vnc_row = Adw.SwitchRow(
            title="WayVNC server",
            subtitle="Remote access to this machine's screen",
        )
        self.desk_row.notify.connect(self.update_vnc_sensitivity)
        roles.add(self.nas_row)
        roles.add(self.vnc_row)

        kb = Adw.PreferencesGroup(title="Keyboard (optional)")
        self.kb_row = Adw.SwitchRow(
            title="Custom layout for this machine",
            subtitle="Off keeps the base default (br/abnt2)",
        )
        self.kb_layout = Adw.EntryRow(title="keymap (e.g. us)")
        self.kb_variant = Adw.EntryRow(title="xkbVariant (e.g. intl)")
        self.kb_row.connect("notify::active", self.update_kb_visibility)
        kb.add(self.kb_row)
        kb.add(self.kb_layout)
        kb.add(self.kb_variant)
        self.kb_layout.set_visible(False)
        self.kb_variant.set_visible(False)

        generate = Gtk.Button(label="Collect answers", css_classes=["suggested-action"])
        generate.connect("clicked", self.on_collect)
        button_group = Adw.PreferencesGroup()
        button_group.add(Adw.ActionRow(child=generate, valign=Gtk.Align.CENTER))

        page.add(group)
        page.add(roles)
        page.add(kb)
        page.add(button_group)
        self.machine_page = page

    def build_apps_page(self):
        page = Adw.PreferencesPage()
        top = Adw.PreferencesGroup(title="Apps from the profile")
        top.set_description(
            "Everything enabled in the personal profile applies to this machine. "
            "Uncheck what this machine should NOT have."
        )
        self.app_checks = {}

        scroll_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        for category in sorted(self.catalog):
            group = Adw.PreferencesGroup(title=category.title())
            for app in sorted(self.catalog[category]):
                row = Adw.SwitchRow(title=app)
                row.set_active(True)
                self.app_checks[f"{category}.{app}"] = row
                group.add(row)
            scroll_box.append(group)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_child(scroll_box)
        scrolled.set_vexpand(True)
        scrolled.set_hexpand(True)

        page.add(top)
        page_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        page_box.set_vexpand(True)
        page_box.append(scrolled)
        self.apps_page = page
        self.apps_box = page_box
        page.add(
            Adw.PreferencesGroup(description="The engine auto-adjusts assertion rules (e.g. davinci-resolve off on virtio).")
        )
        self.apps_placeholder = page

    def build_progress_page(self):
        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        page.set_margin_top(12)
        page.set_margin_bottom(12)
        page.set_margin_start(12)
        page.set_margin_end(12)

        self.summary_label = Gtk.Label(wrap=True, xalign=0)
        page.append(self.summary_label)

        scrolled = Gtk.ScrolledWindow()
        self.output_view = Gtk.TextView()
        self.output_view.set_editable(False)
        self.output_view.set_monospace(True)
        self.output_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        scrolled.set_child(self.output_view)
        scrolled.set_vexpand(True)
        page.append(scrolled)

        button_box = Gtk.Box(spacing=12)
        self.generate_button = Gtk.Button(
            label="Generate host and validate", css_classes=["suggested-action"]
        )
        self.generate_button.connect("clicked", self.on_generate)
        self.test_button = Gtk.Button(label="Run rebuild test (sudo)", sensitive=False)
        self.test_button.connect("clicked", self.on_run, ["test"])
        self.switch_button = Gtk.Button(
            label="Make it the boot default (sudo)", sensitive=False, css_classes=["destructive-action"]
        )
        self.switch_button.connect("clicked", self.on_run, ["switch"])
        button_box.append(self.generate_button)
        button_box.append(self.test_button)
        button_box.append(self.switch_button)
        page.append(button_box)

        page.append(
            Gtk.Label(
                label="The installer never commits. Rollback: sudo nixos-rebuild switch --rollback",
                css_classes=["caption"], xalign=0,
            )
        )
        self.progress_page = page

    # -------------------------------------------------------------- reactions

    def update_vnc_sensitivity(self, *_):
        sel = self.desk_row.get_selected_item()
        desktop = sel.get_string() if sel else ""
        allowed = desktop in ("hyprland", "sway")
        self.vnc_row.set_sensitive(allowed)
        if not allowed and self.vnc_row.get_active():
            self.vnc_row.set_active(False)

    def update_kb_visibility(self, row, *_):
        active = row.get_active()
        self.kb_layout.set_visible(active)
        self.kb_variant.set_visible(active)

    def combo_value(self, row):
        item = row.get_selected_item()
        return item.get_string() if item else ""

    def collect(self):
        name = self.name_row.get_text().strip()
        if not HOSTNAME_RE.match(name):
            return None, "Invalid machine name (letters, numbers, hyphens)."
        if name in ("common", "profiles"):
            return None, "common and profiles are reserved names."
        if name in self.existing_hosts:
            return None, f"hosts/{name} already exists (the installer never overwrites)."
        answers = {
            "hostname": name,
            "gpu": self.combo_value(self.gpu_row),
            "firmware": self.combo_value(self.fw_row),
            "desktop": self.combo_value(self.desk_row),
            "profile": "gabrielnathan",
            "nas": self.nas_row.get_active(),
            "vnc": self.vnc_row.get_active(),
            "keyboard": (
                {
                    "keymap": self.kb_layout.get_text().strip() or "us",
                    "xkbVariant": self.kb_variant.get_text().strip(),
                }
                if self.kb_row.get_active()
                else None
            ),
            "disable": [
                path for path, row in self.app_checks.items() if not row.get_active()
            ],
        }
        if answers["vnc"] and answers["desktop"] not in ("hyprland", "sway"):
            answers["vnc"] = False
        return answers, None

    def on_collect(self, *_):
        answers, error = self.collect()
        if error:
            dialog = Adw.AlertDialog(heading="Check the answers", body=error)
            dialog.present(self.win)
            return
        self.answers = answers
        disabled = len(answers["disable"])
        self.summary_label.set_text(
            f"Ready: hosts/{answers['hostname']} — {answers['gpu']} / {answers['firmware']}"
            f" / {answers['desktop']}"
            + (f" — NAS" if answers["nas"] else "")
            + (f" — VNC" if answers["vnc"] else "")
            + (f" — {disabled} app(s) disabled" if disabled else " — all profile apps on")
        )
        self.stack.set_visible_child(self.progress_page)

    def append_output(self, text):
        buf = self.output_view.get_buffer()
        end = buf.get_end_iter()
        buf.insert(end, text)
        adj = self.output_view.get_vadjustment()
        adj.set_value(adj.get_upper())

    def on_generate(self, *_):
        if self.proc and self.proc.poll() is None:
            return
        answers_file = REPO / "scripts/fixtures/.gui-answers.json"
        answers_file.write_text(json.dumps(self.answers, indent=2))
        self.output_view.get_buffer().set_text("")
        self.test_button.set_sensitive(False)
        self.switch_button.set_sensitive(False)
        self.generate_button.set_sensitive(False)
        self.append_output("$ hamra-init --answers .gui-answers.json\n\n")
        self.proc = subprocess.Popen(
            [
                sys.executable,
                str(ENGINE),
                "--answers",
                str(answers_file),
            ],
            cwd=REPO,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        GLib.io_add_watch(
            self.proc.stdout, GLib.IO_IN | GLib.IO_HUP, self.on_engine_output
        )

    def on_engine_output(self, source, condition):
        if condition & GLib.IO_IN:
            line = source.readline()
            if line:
                self.append_output(line)
        if condition & GLib.IO_HUP or (self.proc.poll() is not None):
            code = self.proc.wait()
            self.append_output(f"\n[engine exit: {code}]\n")
            if code == 0:
                self.test_button.set_sensitive(True)
            else:
                self.generate_button.set_sensitive(True)
            return False
        return True

    def on_run(self, button, mode):
        hostname = self.answers["hostname"]
        if mode == "test":
            self.on_engine_run(
                ["sudo", "sh", "-c",
                 "mkdir -p /root/.config/nix; grep -q '^experimental-features' "
                 "/root/.config/nix/nix.conf 2>/dev/null || echo "
                 "'experimental-features = nix-command flakes' "
                 ">> /root/.config/nix/nix.conf"],
                then=[
                    "sudo", "nixos-rebuild", "test", "--flake", f".#{hostname}"
                ],
            )
        else:
            dialog = Adw.AlertDialog(
                heading="Make it the boot default?",
                body=f"sudo nixos-rebuild switch --flake .#{hostname}\n\n"
                "Rollback: sudo nixos-rebuild switch --rollback",
            )
            dialog.add_response("cancel", "Cancel")
            dialog.add_response("switch", "Switch")
            dialog.set_response_appearance(
                "switch", Adw.ResponseAppearance.SUGGESTED
            )
            dialog.choose(self.win, None, self.on_switch_confirmed)

    def on_switch_confirmed(self, dialog, task):
        if dialog.choose_finish(task) == "switch":
            self.on_engine_run(
                ["sudo", "nixos-rebuild", "switch", "--flake", f".#{self.answers['hostname']}"]
            )

    def on_engine_run(self, prep, then):
        def do_then():
            self.append_output(f"\n$ {' '.join(then)}\n\n")
            self.subproc = subprocess.Popen(
                then, cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
            )
            GLib.io_add_watch(
                self.subproc.stdout, GLib.IO_IN | GLib.IO_HUP, self.on_sub_output
            )

        if prep:
            self.append_output(f"\n$ {' '.join(prep)} (one-time root setup)\n\n")
            subprocess.run(prep, cwd=REPO)
        do_then()

    def on_sub_output(self, source, condition):
        if condition & GLib.IO_IN:
            line = source.readline()
            if line:
                self.append_output(line)
        if condition & GLib.IO_HUP or (self.subproc.poll() is not None):
            code = self.subproc.wait()
            self.append_output(f"\n[exit: {code}]\n")
            if code == 0:
                self.switch_button.set_sensitive(True)
            return False
        return True


if __name__ == "__main__":
    if not (REPO / "flake.nix").is_file():
        print(f"repository not found at {REPO} (set HAMRA_REPO)", file=sys.stderr)
        sys.exit(1)
    app = SetupApp()
    app.run(sys.argv)
