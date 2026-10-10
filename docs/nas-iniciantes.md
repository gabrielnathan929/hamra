# Hamra NAS — a guide for anyone who has never messed with this

This guide is for ANYONE who wants to set up the NAS (the "homemade
cloud") on any PC using this repository. You **don't need to understand
encryption or NixOS** — the `setup-nas` assistant does everything,
explaining each step. When an error shows up, it tells you **what to
do next**.

> Quick concept: the NAS is a network folder shared between PCs.
> This repository keeps its password **encrypted**. The crypto
> keys are the "padlocks" that open this password.

---

## 1. In one go (the happy path)

On a PC with NixOS, this repository cloned into one of your folders
(e.g. `~/Projetos/hamra`) and the `/etc/nixos` symlink pointing to it:

```bash
cd ~/Projetos/hamra
nix develop              # sets up the tools (first run takes a while)
./scripts/setup-nas.sh   # the guided assistant
```

The assistant asks for just a few things (PC name, GPU, desktop, and
**your** NAS password) and then:

1. creates this PC's "host" in the repository (config files);
2. generates the **edit** key for the secrets (if it doesn't exist here
   yet);
3. registers this PC's key in `.sops.yaml`;
4. stores your password encrypted in `secrets/samba.yaml`;
5. asks whether you want to **apply** it on the PC (recommended) and,
   if you confirmed, reconfigures the system — Samba starts sharing
   the `shared`, `games` and `backups` folders.

Done. Any other PC can connect: same script **on that PC**.

---

## 2. First steps on a new PC (detailed step by step)

### 2.1. Get the repository on the machine

```bash
git clone <repository-url> ~/Projetos/hamra
sudo ln -s ~/Projetos/hamra /etc/nixos
```

> Replace `<repository-url>` with the GitHub "Clone" link
> (green button). E.g. `https://github.com/youruser/hamra.git`. The
> clone can live in any folder of your user — the `/etc/nixos` symlink
> is what makes the tools find the repo; create it just once.

### 2.2. Enter the working environment

```bash
cd ~/Projetos/hamra
nix develop
```

This command installs (on the first run) the tools: `sops`, `age`,
`ssh-to-age`, `python3`. It doesn't change your system — it's just a
temporary "toolbox".

### 2.3. Run the assistant

```bash
./scripts/setup-nas.sh
```

What each question means:

| Question | What it is | Tip |
|---|---|---|
| Name of this PC in the repository | The machine's nickname in the repo files | Can be the PC's name, e.g. `laptop`, `server`, `desktop` |
| PC GPU | Graphics card | `intel`, `amd`, `nvidia` or `virtio` (virtual machines) |
| Firmware | Boot type | `uefi` (default) or `bios` |
| Desktop | Graphical environment | `hyprland`, `sway`, `niri`, `gnome` or `plasma` |
| System user | Your Linux user | The same one from the install (e.g. `gabrielnathan`) |
| NAS password | **Your** password for the share | Minimum 8 characters. Typed 2× and never shown on screen |

Keep the suggested answer (in brackets) by just pressing **Enter** if
you don't know.

### 2.4. Publish to the repository

At the end the assistant shows:

```bash
git add -A && git commit -m "Add NAS setup" && git push
```

This way the repository becomes the "source of truth": **any PC can
recreate** the same configuration just by following this guide.

---

## 3. I forgot the NAS password (it happens!)

Inside the repository:

```bash
nix develop
./scripts/setup-nas.sh --mostrar-senha
```

It shows the password on screen. For the command to work, the PC needs
**one** of the two things:

- the edit key in `~/.config/sops/age/keys.txt`; or
- this PC's SSH key registered in `.sops.yaml` (on NixOS this is
  automatic, nothing to do).

### I lost the edit key **and** my PC isn't registered

The `secrets/samba.yaml` file won't open (that's exactly the
protection). Solutions:

- **Best route:** ask someone who has the repository with access to
  run on their PC:
  ```bash
  nix develop
  printf 'y\n' | sops updatekeys secrets/samba.yaml   # adds your PC
  ```
  and publish. Then, on your PC, `--mostrar-senha` starts working.
- **Drastic alternative:** delete the secret and recreate it with a
  new password:
  ```bash
  rm secrets/samba.yaml && ./scripts/setup-nas.sh --reset-senha
  ```
  The new password takes effect on the next `nixos-rebuild switch`
  of any host with Samba active (the activation script syncs it
  automatically). CLIENTS MUST USE THE NEW PASSWORD.

---

## 4. I want to change the password

```bash
nix develop
./scripts/setup-nas.sh --reset-senha
```

It changes, re-encrypts and syncs the registered PCs. Then run on each
Samba host:

```bash
sudo nixos-rebuild switch --flake ~/Projetos/hamra#<host>
```

And update the clients (`/etc/samba/cred-nas` file, if used).

---

## 5. Just check the environment, without changing anything

```bash
nix develop
./scripts/setup-nas.sh --check
```

Lists what exists and what's missing. Great for diagnosing before
running the assistant. `./scripts/setup-nas.sh --ajuda` (or `-h`) prints
the same summary as the script header.

---

## 6. Using the NAS from other PCs (clients)

### Linux (Arch/any distro)

Create the credentials file (once):

```bash
sudo pacman -S cifs-utils                      # Arch
echo 'username=gabrielnathan' | sudo tee /etc/samba/cred-nas
echo 'password=your-password' | sudo tee -a /etc/samba/cred-nas
sudo chmod 600 /etc/samba/cred-nas
```

Mount (or put these lines in `/etc/fstab` to mount automatically):

```fstab
//NAS-IP/shared     /mnt/nas-shared  cifs  credentials=/etc/samba/cred-nas,uid=1000,gid=100,iocharset=utf8,noauto,x-systemd.automount,x-systemd.idle-timeout=60 0 0
//NAS-IP/games      /mnt/nas-games   cifs  credentials=/etc/samba/cred-nas,uid=1000,gid=100,iocharset=utf8,noauto,x-systemd.automount,x-systemd.idle-timeout=60 0 0
//NAS-IP/backups    /mnt/nas-backups cifs  credentials=/etc/samba/cred-nas,uid=1000,gid=100,iocharset=utf8,noauto,x-systemd.automount,x-systemd.idle-timeout=60 0 0
```

```bash
sudo mkdir -p /mnt/nas-{shared,games,backups}
sudo mount -a
```

> The NAS IP shows up with `ip a` on the PC with Samba enabled.
> If you want a fixed IP, reserve it in the router (local network) or
> configure a static address.

### Windows

In File Explorer, address: `\\NAS-IP\shared` \
(When asked for the user, use `gabrielnathan` and the NAS password.)

### Mac

Finder → Go → Connect to Server → `smb://NAS-IP/shared`

---

## 7. Common problems (and what to do)

| Error / situation | What's going on | Solution |
|---|---|---|
| `Missing tools: ...` | You're not in the environment | Run `nix develop` and try again |
| `no matching creation rules found` | A file in the wrong place got encrypted | Rarely manual; run the assistant again — it writes the draft in the right folder |
| `sops metadata not found` | sops found the file "half encrypted" | Run again; if it persists, `rm secrets/samba.yaml && ./scripts/setup-nas.sh --reset-senha` |
| `Couldn't find <ip> ... shared` when mounting | Samba down or wrong IP | `sudo systemctl status samba-smbd.service` on the NAS; check the IP |
| Password not accepted when mounting | Outdated credential | Redo section 6 (or section 4 if you changed the password) |
| Rebuild fails | Some NixOS validation rejected the config | Read the error; the assistant points out the command to rerun |
| I forgot the password | — | Section 3 of this guide |

---

## 8. Security — what can and can NOT go to GitHub

**Can go (it's encrypted):**

- `secrets/samba.yaml` — contains the password, but ciphered. Without
  the keys, nobody reads it.

**NEVER commit:**

- `~/.config/sops/age/keys.txt` — it's the "master password" of the
  secrets.
- `/etc/ssh/ssh_host_ed25519_key` (private file — the `.pub` is ok).
- Passwords in plain text, in any file.

---

## 9. The NAS trash bin (anti-wipe)

Deleting a file/folder **through the share** (Windows, Mac, Linux)
doesn't really delete it: Samba moves everything to a **trash bin**
inside the share itself, in the hidden `.trash` folder
(`/data/shared/.trash`, `/data/games/.trash`, `/data/backups/.trash`).

- **How to view:** on Windows enable "Hidden items"; on Linux, `ls -a`
  in the mounted folder. Folders keep the origin structure
  (`keeptree`) and the date.
- **Duplicate:** if you delete a name that's already in the trash, it
  keeps **both versions** (suffix with the date) — nothing is lost to
  overwriting.
- **Recover:** just move the file back to the original folder.
- **Empty:** delete whatever you want from inside `.trash` (it uses
  disk space — clean it out now and then).

Honest limitations:

- It protects against deletion **over the network (SMB)** — including
  Windows' Shift+Delete. A direct `rm` on the server **really
  deletes**: don't go around running `rm` on the machine hosting the
  NAS.
- Temporary files (`.tmp`, `~$`... from Office) leave **without**
  passing through the trash (to keep it from piling up).
- The trash lives on the same disk — it's a bumper against
  **accidents**, not a backup. For a real copy, see the section about
  backups.
