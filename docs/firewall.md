# Firewall guide

The firewall is configured per host in `config/system.nix`:

```nix
hamra.firewall = {
  enable = true;
  ports = {
    ssh = true;
    dev = true;
  };
};
```

`ports` is a named menu — unknown names fail the build (assertion in
`modules/nixos/core/firewall.nix`).

| Port | Opens |
|---|---|
| `ssh` (default `true`) | TCP 22 |
| `mosh` | UDP 60000-61000 |
| `http` | TCP 80 |
| `https` | TCP 443 |
| `dev` | TCP 3000-3001/4000/4200/5000-5001/5173-5174/8000-8001/8080-8082/9000/19000-19002/4173 |
| `rdp` | TCP 3389 |
| `syncthing` | TCP 8384/22000 + UDP 21027 |
| `kdeconnect` | TCP+UDP 1714-1764 |
| `jellyfin` | TCP 8096/8920 + UDP 1900/7359 |
| `printer` | TCP 631 + UDP 5353 |
| `mpd` | TCP 6600 |

Setting `enable = false` disables the firewall entirely (everything opens).

## Ports owned by service toggles

Some toggles ship their own server and open their ports themselves, so they
are not in the menu:

| Toggle | Ports |
|---|---|
| `services.wayvnc` | TCP 5900 |
| `services.samba` | TCP 139/445 + UDP 137/138 |
| `services.sunshine` | Sunshine/Moonlight ports |
| `services.localsend` | LocalSend discovery/transfer ports |

## Testing the `dev` ports from a phone

Bind the dev server to all interfaces, e.g. `vite --host`, then open
`http://<pc-lan-ip>:5173` on the phone. The `dev` entry already covers the
usual Vite/Next/Angular/Django ports.

## Verifying

```bash
nix eval .#nixosConfigurations.<host>.config.networking.firewall.allowedTCPPorts
sudo iptables -S | grep -E '22|5900'
```
