#!/usr/bin/env gjs
// Foundry — shape your NixOS machine visually.
//
// A GNOME app (GJS + GTK4 + libadwaita) that reads the machine's
// configuration and lets you toggle apps on/off with a switch.
//
// Zero compilation, one dependency (gjs). The engine (hamra-init)
// stays as the CLI backend; this is the visual layer.

imports.gi.versions.Gtk = '4.0';
imports.gi.versions.Adw = '1';

const {Gtk, GLib, Gio, GObject} = imports.gi;
const Adw = imports.gi.Adw;

const REPO = GLib.getenv('HAMRA_REPO') || GLib.get_current_dir();
const HOSTNAME = readFile('/proc/sys/kernel/hostname').trim();

function readFile(path) {
    const [ok, content] = GLib.file_get_contents(path);
    return ok ? content.toString() : '';
}

function nixEvalJson(expr) {
    try {
        const [_, stdout, stderr, exitCode] = GLib.spawn_command_line_sync(
            `nix eval --json ${expr}`
        );
        if (exitCode !== 0) {
            printerr(`nix eval failed: ${stderr}`);
            return null;
        }
        return JSON.parse(stdout.toString());
    } catch (e) {
        printerr(`nix eval error: ${e}`);
        return null;
    }
}

function findProfile() {
    const dir = `${REPO}/hosts/profiles`;
    try {
        const [_, files] = GLib.dir_open(dir, 0);
        const entries = [];
        let name;
        while ((name = files.read_name()) !== null) {
            entries.push(name);
        }
        return entries[0] || 'gabrielnathan';
    } catch (e) {
        return 'gabrielnathan';
    }
}

function readHostConfig() {
    const path = `${REPO}/hosts/${HOSTNAME}/configuration.nix`;
    const content = readFile(path);
    const overrides = {};

    for (const line of content.split('\n')) {
        const trimmed = line.trim();
        const match = trimmed.match(/programs\.optionals\.(\w+)\.(\S+)\s*=\s*(true|false)/);
        if (match) {
            overrides[`${match[1]}.${match[2].replace(/"/g, '')}`] = match[3] === 'true';
        }
    }
    return overrides;
}

function generateHostNix(state) {
    let out = `_: {
  imports = [
    ../../modules/nixos/core
    ../../modules/nixos/desktops
    ../../modules/nixos/programs
    ../common
    ../profiles/${state.profile}
    ./hardware-configuration.nix
  ];

  hamra = {
    networking.hostname = "${state.hostname}";

    hardware = {
      gpu = "${state.gpu}";
      firmware = "${state.firmware}";
    };
`;

    if (state.keymap) {
        out += `
    keyboard = {
      keymap = "${state.keymap}";`;
        if (state.xkbVariant) {
            out += `
      xkbVariant = "${state.xkbVariant}";`;
        }
        out += `
    };
`;
    }

    out += `
    desktop.default = "${state.desktop}";
`;

    const categories = {};
    for (const [path, value] of Object.entries(state.overrides)) {
        const [cat, ...rest] = path.split('.');
        const app = rest.join('.');
        if (!categories[cat]) categories[cat] = [];
        categories[cat].push([app, value]);
    }

    for (const [cat, apps] of Object.entries(categories).sort()) {
        out += `\n    programs.optionals.${cat} = {\n`;
        for (const [app, value] of apps.sort((a, b) => a[0].localeCompare(b[0]))) {
            const name = app.includes('-') ? `"${app}"` : app;
            out += `      ${name} = ${value};\n`;
        }
        out += `    };\n`;
    }

    out += `  };
}
`;
    return out;
}

function saveHostNix(state) {
    const content = generateHostNix(state);
    const tmpPath = `${REPO}/hosts/${HOSTNAME}/.configuration.nix.tmp`;
    const finalPath = `${REPO}/hosts/${HOSTNAME}/configuration.nix`;

    GLib.file_set_contents(tmpPath, content);
    GLib.rename(tmpPath, finalPath);
}

// ─── Application ─────────────────────────────────────────────────────────

const FoundryApp = GObject.registerClass(
    class FoundryApp extends Adw.Application {
        _init() {
            super._init({
                application_id: 'dev.foundry',
                flags: Gio.ApplicationFlags.FLAGS_NONE,
            });
        }

        vfunc_activate() {
            super.vfunc_activate();

            if (!Gio.File.new_for_path(`${REPO}/flake.nix`).query_exists(null)) {
                printerr(`foundry: flake.nix not found in ${REPO}`);
                printerr('Run from the Hamra checkout or set HAMRA_REPO.');
                this.quit();
                return;
            }

            this._buildWindow();
        }

        _buildWindow() {
            const win = new Adw.ApplicationWindow({
                application: this,
                default_width: 880,
                default_height: 640,
                title: 'Foundry',
            });

            const hostData = nixEvalJson(
                `.#nixosConfigurations.${HOSTNAME}.config.hamra`
            ) || {};

            const appsData = nixEvalJson(
                `.#nixosConfigurations.${HOSTNAME}.config.hamra.programs.optionals`
            ) || {};

            const hostsData = nixEvalJson(
                `--file ${REPO}/flake/hosts.nix --apply 'x: builtins.attrNames x'`
            ) || [];

            const profile = findProfile();
            const overrides = readHostConfig();

            this._state = {
                hostname: HOSTNAME,
                gpu: hostData.hardware?.gpu || 'intel',
                firmware: hostData.hardware?.firmware || 'uefi',
                desktop: hostData.desktop?.default || 'hyprland',
                keymap: hostData.keyboard?.keymap || null,
                xkbVariant: hostData.keyboard?.xkbVariant || null,
                overrides,
                profile,
            };

            // ─── Header ──────────────────────────────────────────

            const header = new Adw.HeaderBar();
            const viewStack = new Adw.ViewStack();
            const switcher = new Adw.ViewSwitcher({
                stack: viewStack,
                policy: Adw.ViewSwitcherPolicy.WIDE,
            });
            header.set_title_widget(switcher);

            // ─── Overview page ────────────────────────────────────

            const overview = new Gtk.Box({
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 24,
                margin_top: 32, margin_bottom: 32,
                margin_start: 32, margin_end: 32,
            });

            const titleLabel = new Gtk.Label({
                label: HOSTNAME,
                css_classes: ['title-1'],
            });
            overview.append(titleLabel);

            const infoGroup = new Adw.PreferencesGroup({ title: 'Machine' });
            for (const [label, value] of [
                ['GPU', this._state.gpu],
                ['Firmware', this._state.firmware],
                ['Desktop', this._state.desktop],
            ]) {
                infoGroup.add(new Adw.ActionRow({ title: label, subtitle: value }));
            }
            overview.append(infoGroup);

            if (hostsData.length > 0) {
                const hostsGroup = new Adw.PreferencesGroup({ title: 'Registered hosts' });
                for (const host of hostsData) {
                    hostsGroup.add(new Adw.ActionRow({ title: host }));
                }
                overview.append(hostsGroup);
            }

            const actionGroup = new Adw.PreferencesGroup();
            const rebuildBtn = new Gtk.Button({
                label: 'Rebuild & Apply',
                css_classes: ['suggested-action'],
            });
            rebuildBtn.connect('clicked', () => {
                const dialog = new Adw.AlertDialog({
                    heading: 'Rebuild',
                    body: `sudo nixos-rebuild test --flake .#${HOSTNAME}\n\nThis does NOT change the boot menu.`,
                });
                dialog.add_response('cancel', 'Cancel');
                dialog.add_response('run', 'Run');
                dialog.choose(win, null, (dlg, task) => {
                    if (dlg.choose_finish(task) === 'run') {
                        try {
                            const [proc] = GLib.spawn_async(
                                REPO,
                                ['sudo', 'nixos-rebuild', 'test', '--flake', `.#${HOSTNAME}`],
                                null,
                                GLib.SpawnFlags.SEARCH_PATH | GLib.SpawnFlags.DO_NOT_REAP_CHILD,
                                null
                            );
                            const toast = new Adw.Toast({
                                title: 'Rebuild started — check the terminal',
                                timeout: 3,
                            });
                            this._toastOverlay.add_toast(toast);
                        } catch (e) {
                            printerr(e);
                        }
                    }
                });
            });
            const actionRow = new Adw.ActionRow();
            actionRow.add_suffix(rebuildBtn);
            actionGroup.add(actionRow);
            overview.append(actionGroup);

            // ─── Apps page ────────────────────────────────────────

            const appsPage = new Gtk.Box({
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 12,
                margin_top: 24, margin_bottom: 24,
                margin_start: 24, margin_end: 24,
            });

            const searchBar = new Gtk.SearchBar();
            const searchEntry = new Gtk.SearchEntry({
                placeholder_text: 'Search apps…',
            });
            searchBar.set_child(searchEntry);
            appsPage.append(searchBar);

            const scroll = new Gtk.ScrolledWindow({ vexpand: true });
            const content = new Gtk.Box({
                orientation: Gtk.Orientation.VERTICAL,
                spacing: 12,
            });

            const allRows = [];

            for (const [category, apps] of Object.entries(appsData).sort()) {
                const group = new Adw.PreferencesGroup({
                    title: category.toUpperCase(),
                });

                for (const [app, enabled] of Object.entries(apps).sort()) {
                    const row = new Adw.ActionRow({ title: app });

                    const sw = new Gtk.Switch({
                        valign: Gtk.Align.CENTER,
                    });
                    sw.set_active(enabled);

                    const overrideKey = `${category}.${app}`;
                    if (overrides[overrideKey] !== undefined) {
                        sw.add_css_class('accent');
                    }

                    sw.connect('notify::active', (widget) => {
                        const active = widget.get_active();
                        this._state.overrides[overrideKey] = active;

                        try {
                            saveHostNix(this._state);
                            const toast = new Adw.Toast({
                                title: active ? `${app} enabled` : `${app} disabled`,
                                timeout: 2,
                            });
                            this._toastOverlay.add_toast(toast);
                            if (active) {
                                sw.remove_css_class('accent');
                            } else {
                                sw.add_css_class('accent');
                            }
                        } catch (e) {
                            printerr(`save failed: ${e}`);
                            widget.set_active(!active);
                        }
                    });

                    row.add_suffix(sw);

                    const searchText = `${category} ${app}`.toLowerCase();
                    allRows.push({ row, searchText });
                    group.add(row);
                }
                content.append(group);
            }

            searchEntry.connect('changed', (entry) => {
                const query = entry.text.toLowerCase();
                for (const {row, searchText} of allRows) {
                    row.visible = query === '' || searchText.includes(query);
                }
            });

            scroll.set_child(content);
            appsPage.append(scroll);

            // ─── Assemble ─────────────────────────────────────────

            this._toastOverlay = new Adw.ToastOverlay();

            viewStack.add_titled(overview, 'overview', 'Overview');
            viewStack.add_titled(appsPage, 'apps', 'Apps');

            const root = new Gtk.Box({
                orientation: Gtk.Orientation.VERTICAL,
            });
            root.append(header);

            const stackBox = new Gtk.Box({
                orientation: Gtk.Orientation.VERTICAL,
                vexpand: true,
            });
            stackBox.append(viewStack);
            this._toastOverlay.set_child(stackBox);
            root.append(this._toastOverlay);

            win.set_content(root);
            win.present();
        }
    }
);

const app = new FoundryApp();
app.run([]);
