# Remote Desktop (VNC)

Hamra serves the desktop with **wayvnc** (`services.wayvnc`) and connects with
any VNC client. The server exposes a **headless output** (`HEADLESS-N`, defined
by `hamra.displays.headless`) so the remote session is independent of the
physical screen.

| Toggle | Role |
|--------|------|
| `services.wayvnc` | VNC **server** (wayvnc + systemd user unit, TCP 5900) |
| `services.tigervnc` | VNC **client** tools (`vncviewer`) |
| `services."vnc-client"` | **Background client** that connects automatically and reconnects |

All are plain toggles in the host file; the same machine can be server and
client.

---

## What the server accepts

wayvnc delegates the RFB handshake to **neatvnc**, which implements only a
subset of the security types:

| Client option | Server side | Credentials | Works |
|---------------|-------------|-------------|-------|
| `X509Plain` (VeNCrypt TLS) | static TLS cert + key (`wayvnc-tls-key`) | user + password | **yes — what `vnc-client` uses** |
| `RA2` / `RA2_256` (RSA-AES) | static RSA key (`wayvnc-rsa-key`) | user + password | yes, prompts the fingerprint |
| `TLSVnc`, `TLSPlain`, `X509Vnc`, `X509None` | — | — | no: `No valid VeNCrypt sub-type` |
| `VncAuth` (classic DES) | — | password | no: rejected by this build |

So every working session uses **username + password**. The username is
`hamra.users.userName`; the password comes from `secrets/vnc.yaml`.

---

## Automatic client (`vnc-client`)

Turning on `services."vnc-client"` makes the client host connect by itself:

- the compositor starts `vnc-client.service` at login (Hyprland, Sway or Niri);
- the unit runs **TigerVNC** with `-SecurityTypes X509Plain -X509CA <cert>`,
  so the TLS certificate pinned in the repo replaces the fingerprint prompt;
  `-RemoteResize=0` keeps the viewer from asking the server to resize (and
  move) the virtual output to the window size;
- username and password come from the sops secret at
  `/run/secrets/vnc-password` (`VNC_USERNAME` + `VNC_PASSWORD`, no dialog);
- `Restart=always` with `RestartSec=5`: if the link drops the viewer exits and
  systemd brings it back — no need to start the server first, the client keeps
  retrying until it appears.

The target is the **same** `hamra.home.programs.shell.vncHost` used by the
alias, so there is one place to change:

```nix
# hosts/<client>/config/home.nix
shell = {
  aliases = true;
  flakeDir = "$HOME/Projetos/hamra";
  vncHost = "192.168.1.15:5900";
};

# hosts/<client>/config/programs-optionals.nix
services = {
  "vnc-client" = true;
  tigervnc = true;
};
```

Aliases that come with it (only when `vncHost` is set):

| Alias | Does |
|-------|------|
| `vnc` | `systemctl --user start vnc-client` (opens the viewer now) |
| `vnc-restart` | `systemctl --user restart vnc-client` |
| `vnc-stop` | `systemctl --user stop vnc-client` |
| `vnc-status` | `systemctl --user status vnc-client` + logs |

Changes to the wrapper need a restart: `vnc-restart` after a rebuild.

---

## Connecting manually

Without `vnc-client`, the client host gets a `vnc` alias that runs the viewer
in the foreground:

```bash
vnc            # vncviewer -SecurityTypes RA2 <vncHost>
```

The full command, if you want another server:

```bash
vncviewer -SecurityTypes RA2 <server-ip>:5900
```

1. A dialog shows the server **fingerprint** of the RSA key
   (`The server has provided the following identifying information`).
   Press **Yes/Sim** the first time — it identifies the server key, and the
   same key is reused across reboots because it lives in sops.
2. Type the **username** and the **password** (option *Keep password for
   reconnect* stores it for the next sessions).
3. The virtual desktop opens; the window resizes to the headless output.

Without `-SecurityTypes` the client picks the first type it supports, which is
`VncAuth` — that is why the flag is required.

`X509Plain` with `-X509CA` also works interactively and skips the fingerprint
step (only the user/password dialog remains):

```bash
vncviewer -SecurityTypes X509Plain -X509CA /path/to/wayvnc-cert.pem <host>:5900
```

### Remmina

Remmina is **off by default** (`gui/remmina = false` on the hosts). If you
prefer it, enable the toggle and know that it negotiates VeNCrypt, so it lands
on `X509Plain` and asks for certificate files:

| Field | Value |
|-------|-------|
| CA certificate / Certificado de AC | `modules/nixos/programs/optionals/services/wayvnc-cert.pem` |
| CA CRL, client certificate, client key | leave empty |

Then username + password. The certificate is self-signed with `CN=wayvnc` and
`subjectAltName = IP:127.0.0.1, IP:::1`, so hostname/IP verification must stay
off. TigerVNC avoids all of this.

---

## Server side

`services.wayvnc` does, on start:

1. waits for the compositor (Hyprland or Sway — asserted in `core/assertions.nix`);
2. creates/reuses the headless output from `hamra.displays.headless`
   (mode, position, scale) and pins workspaces 6-10 to it; if the output exists
   with the wrong size or position (for example after a client resized it), it
   is recreated;
3. writes `$XDG_RUNTIME_DIR/wayvnc.conf` (mode 0600) with the password read
   from `/run/secrets/vnc-password` and the static TLS/RSA key paths;
4. execs `wayvnc` on port 5900 with `--disable-resizing`: the virtual output
   keeps the configured resolution, so the client scales the image instead of
   resizing/moving the output over the physical screen.

The unit is a **user** service: `systemctl --user status wayvnc`.

| Secret | sops file | Key | Used as |
|--------|-----------|-----|---------|
| VNC password | `secrets/vnc.yaml` | `vnc-password` | `password=` in wayvnc.conf |
| TLS private key | `secrets/wayvnc-tls.yaml` | `wayvnc-tls-key` | `private_key_file=` |
| RSA private key | `secrets/wayvnc-rsa.yaml` | `wayvnc-rsa-key` | `rsa_private_key_file=` |
| TLS certificate (public) | in repo | — | `certificate_file=` |

Key formats are not arbitrary: the TLS key must be a **PKCS#8** PEM that matches
the certificate, and the RSA key must be **PKCS#1** (`BEGIN RSA PRIVATE KEY`) —
nettle rejects PKCS#8 there. `./scripts/setup-vnc.sh --check` validates both.

---

## Managing the credentials

```bash
./scripts/setup-vnc.sh --check            # decrypt + validate everything
./scripts/setup-vnc.sh --show-password    # print the current VNC password
./scripts/setup-vnc.sh --rotate-password  # new password (commit + push)
./scripts/setup-vnc.sh --rotate-certs     # new cert/key + RSA key (commit + push)
./scripts/setup-vnc.sh --rotate-all       # both
```

Always run it on the machine that holds the sops **editing key**
(`~/.config/sops/age/keys.txt`). Manual equivalent:

```bash
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops secrets/vnc.yaml
```

After any rotation, rebuild every host that runs the server:

```bash
sudo nixos-rebuild switch --flake .#<host>
```

`--rotate-certs` changes the server fingerprint, so clients ask for
confirmation once more.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Authentication failed` | wrong password or username | `./scripts/setup-vnc.sh --show-password`; the user is `hamra.users.userName` |
| `Authentication failed` after choosing `VncAuth` | classic DES type is not usable on this build | use `-SecurityTypes RA2` or `X509Plain` |
| `No valid VeNCrypt sub-type` | client requested `TLSVnc`/`X509Vnc` | `-SecurityTypes RA2` or `X509Plain` |
| Remmina asks for "certificate authentication files" | it negotiated `X509Plain` | fill the CA cert field, or use TigerVNC |
| `vnc-client` restarts every 5 s | server host down or wrong `vncHost` | start the server; `vnc-status` shows the log |
| `vnc-client` dies with `Can't open display` | unit started before XWayland exists | it retries; if it persists, check `DISPLAY` in the session |
| `Connection refused` | unit down | `systemctl --user status wayvnc` |
| VNC shows the same screen as the physical monitor ("mirrored") | the headless output was resized/repositioned at `0x0` by the client | restart `wayvnc` (it recreates the output when the geometry is wrong) and see *Server side* |
| Port 5900 unreachable from outside | firewall | the toggle opens 5900; see `docs/firewall.md` |
| Build fails: `attribute 'vnc-password' missing` | server enabled without the secret | `./scripts/setup-vnc.sh --rotate-password` |
| Build fails: `requires hamra.home.programs.shell.vncHost` | `vnc-client` on without a target | set `vncHost` in the host `config/home.nix` |
| Build fails: `requires a configured hamra.displays.headless` | no headless output declared | add `hamra.displays.headless` to the host |
| Server service restarts in a loop | no compositor / headless output | check `journalctl --user -u wayvnc` |
