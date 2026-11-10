# NAS (Samba) guide

Hamra can turn one machine into a small SMB NAS. The toggle lives in the
host file of the machine that **serves** the files:

```nix
hamra.programs.optionals.services.samba = true;
```

Clients need nothing enabled — they just mount the shares.

## What you get

| Share | Path | Purpose |
|---|---|---|
| `shared` | `/data/shared` | general documents |
| `games` | `/data/games` | installers, ROMs, cold storage |
| `backups` | `/data/backups` | notebook backups |

Every share has an automatic trash bin (Samba VFS `recycle`): files deleted
over SMB go to the hidden `.trash` folder, keeping the directory tree and
file versions. It is a bumper against accidents, **not a backup** — a direct
`rm` on the server is not protected.

The password is stored encrypted in `secrets/samba.yaml` and applied on
activation by `system.activationScripts.sync-samba-password`.

## New machine (beginner flow)

```bash
nix develop
./scripts/setup-nas.sh
```

The wizard creates/reuses the host folder, generates the hardware config,
registers this PC's age key (derived from its SSH host key) in `.sops.yaml`,
asks for the NAS password and re-encrypts `secrets/samba.yaml` for every
registered key.

Useful modes:

```bash
./scripts/setup-nas.sh --check           # read-only audit (tools, host key, decrypt)
./scripts/setup-nas.sh --show-password   # print the current NAS password
./scripts/setup-nas.sh --reset-password  # replace the password (all clients must update)
```

## Rule: the secret must open on the NAS

Each machine decrypts with its own `/etc/ssh/ssh_host_ed25519_key`. After
registering a new host key you **must** re-encrypt the secret:

```bash
# on a PC that holds the editing key (~/.config/sops/age/keys.txt)
nix develop --command sops updatekeys secrets/samba.yaml
git add .sops.yaml secrets/samba.yaml
git commit -m "chore(secrets): sync samba recipients"
```

`setup-nas.sh` does this automatically when it can decrypt the file. If it
warns that updatekeys failed, run the command above from the editing machine.

To check a host, run on it:

```bash
nix develop --command sops -d secrets/samba.yaml > /dev/null && echo OK
```

## Mounting from a client

```bash
sudo mkdir -p /mnt/nas
sudo mount -t cifs //<nas-ip>/shared /mnt/nas -o username=<user>,uid=$(id -u),gid=$(id -g)
```

Put the credentials in a root-only file (`/etc/nas-cred`) and use
`credentials=/etc/nas-cred` instead of the password on the command line.
