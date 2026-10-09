# Setup

Install NixOS and bring up Hamra on a new machine. This is the path I use:
graphical ISO and graphical installer, no manual partitioning.

## 1. Install NixOS

1. Download the NixOS graphical ISO (GNOME) from <https://nixos.org/download>,
   flash it to a USB drive and boot from it.
2. Install through the graphical installer. The desktop chosen there does not
   matter — Hamra installs its own. Use the same username you will declare in
   Hamra (`hamra.users.userName`, default `gabrielnathan`) to reuse the home
   created now.
3. Reboot.

Of what the installation generates, only the `hardware-configuration.nix`
(disks, UUIDs, mounts) survives — it is the machine's physical identity. The
installer's `configuration.nix` is discarded in the next step.

## 2. Bring up Hamra

On the first boot, as the user created during installation:

```bash
nix-shell -p git
git clone https://github.com/gabrielnathan929/hamra ~/Projetos/hamra
cd ~/Projetos/hamra
nix --extra-experimental-features "nix-command flakes" run .#hamra-setup
```

Or, if you prefer the terminal:

```bash
nix --extra-experimental-features "nix-command flakes" run .#hamra-init
```

The bootstrap flag is only needed for that single launch — a fresh NixOS
ships without flakes, and the installer needs them to run. Everything else is
automated: the installer enables flakes for your user, and with typed
confirmation backs up the installer's `/etc/nixos` to `/etc/nixos.pre-hamra`
and symlinks the checkout in its place.

Alternatively, **CookieCutter** (the TUI machine shaper) can do the
same from a terminal:

```bash
nix --extra-experimental-features "nix-command flakes" run .#cookiecutter
```

The checkout lives in your user, at any path — `~/Projetos/hamra`,
`~/src/nixos`, `~/dev/hamra`, whatever you prefer. The `/etc/nixos` symlink
points to it and is pure convenience: `nixos-rebuild` without `--flake` and
the `setup-nas` wizard find the repo through the traditional path, and you
edit everything without sudo. Rebuilding through the symlink still preserves
the git revision.

If anything goes wrong before the first switch works, restore the
installer's original configuration with
`sudo rm /etc/nixos && sudo mv /etc/nixos.pre-hamra /etc/nixos` — and delete
the backup once Hamra is stable.

### Fast path: `hamra-init`

```bash
nix run .#hamra-init
```

The wizard asks for the machine name, user, locale, theme, GPU and firmware
(both detected by default), the desktop, display manager, terminal apps and
the host roles (NAS, wayvnc), and performs the
one-time `/etc/nixos` setup when needed. It writes
`hosts/<name>/{configuration,hardware-configuration}.nix` atomically — a
complete host file with every toggle visible, never a delta — and an
existing host is never overwritten — and the host is registered
automatically (hosts are discovered from `hosts/*/`). It then validates in
order: format, lint, `nix flake check` and a full `nix build` of the
toplevel. Only after all gates pass does it offer `nixos-rebuild test`, and
then the switch — both with typed confirmation. It never commits anything
for you.

Non-interactive: `hamra-init --answers answers.json --dry-run` prints the
files without writing. Environment audit only: `hamra-init --check`.

### Manual path (escape hatch)

Copy the most similar host and swap the hardware configuration:

```bash
cp -r hosts/samsung hosts/my-pc
cp /tmp/hardware-configuration.nix hosts/my-pc/
```

Adjust the identity fields in `hosts/my-pc/configuration.nix`:

```nix
hamra = {
  networking.hostname = "my-pc";
  users.userName = "gabrielnathan";

  hardware = {
    gpu = "intel";
    firmware = "uefi";
  };

  desktop.default = "hyprland";
};
```

- `hardware.gpu` — `intel` | `amd` | `nvidia` | `virtio`
- `hardware.firmware` — `uefi` | `bios`
- `desktop.default` — `hyprland` | `niri` | `sway` | `gnome` | `plasma`
- `theme.name` (optional) — `dragon-ball` | `evangelion` | `resident-evil`

Every choice lives in the host file itself — identity, system defaults and
the full true/false toggle menus (e.g. `hamra.programs.optionals.services.samba =
true;` on the NAS).

You may restructure the `hardware-configuration.nix` (group keys), but never
change UUIDs or devices.

## 3. The Samba secret

Samba is a host role (NAS). It is off by default — enable it on the host
that will be the NAS. Its password lives encrypted in
`secrets/samba.yaml`, and that machine must be able to decrypt it at boot —
without it the rebuild fails during activation. Either you register the
machine, or you leave Samba off on it.

Registering, with the wizard:

```bash
nix develop
./scripts/setup-nas.sh
```

It registers this PC's keys in `.sops.yaml`, stores the NAS password
encrypted for the registered PCs and offers the rebuild. On a new machine,
let it create/reset the password — the file must be re-encrypted with this
PC's key. Full guide: [`docs/nas-iniciantes.md`](docs/nas-iniciantes.md).

Or, if this machine is not the NAS, simply do not enable Samba on the host.

## 4. Build and switch

```bash
sudo nixos-rebuild switch --flake .#my-pc
```

The first build takes a while — it downloads the world. From there on,
rebuilds are incremental. Reboot to land on the Hamra desktop.

Day to day there are shortcuts: `nix run .#deploy-<host>` (runs
`nix flake check` before the switch) and `nix run .#build-<host>` (build
without applying, result in `./result`). They are generated automatically for every host under `hosts/`.

With the `/etc/nixos` symlink pointing to the checkout, the simple aliases
work too: `nix-test` and `nix-switch` (nixos-rebuild without `--flake`) use
`/etc/nixos#$(hostname)` — as long as the machine hostname matches its
folder name under `hosts/`.

## Test on the VM

The `vm` host (virtio GPU, sway) exists for trying changes without touching
real hardware. From the repo root:

```bash
nix run .#build-vm
```

builds the `vm` toplevel without applying (result in `./result`). To boot it
as a virtual machine:

```bash
nixos-rebuild build-vm --flake .#vm
./result/bin/run-*-vm
```

The VM runs the same evaluated configuration as a real rebuild, so it
catches evaluation and activation errors before they reach a physical
machine. GUI and hardware-specific behavior (GPU, brightness, bluetooth)
still needs the target machine.

## Validate

```bash
nix fmt
nix flake check
nix develop --command statix check .
nix develop --command deadnix .
```

CI runs the same checks — formatting, lint, evaluation and the build of all
hosts — on every push.
