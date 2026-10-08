## Goal

<!-- What this PR does, in one sentence. -->

## Problem and cause

<!-- What the wrong behavior was and why. -->

## Solution

<!-- What changes and where. -->

## Affected files

<!-- List the files/groups of files. -->

## Risks

<!-- Hardware touched? hosts/common? Secrets? Possible regression? -->

## Validation

- [ ] `nix develop --command alejandra --check .`
- [ ] `nix develop --command statix check .`
- [ ] `nix develop --command deadnix .`
- [ ] `nix flake check`
- [ ] `nix run .#build-<host>` (if structural change)
- [ ] `nixos-rebuild test` before `switch` (if system change)
- [ ] Touches `hosts/*/hardware-configuration.nix`? Justify and validate on the target machine (`lsblk -f`)
- [ ] Does not touch personal layers (`hosts/<machine>/` configs, `hosts/profiles/`) — they stay in forks

## Architectural impact

<!-- Options changing name/default? Host added/removed? Docs updated? -->

## Human intervention required

<!-- Hardware, secrets, remotes, bootloader, auth — or "none". -->
