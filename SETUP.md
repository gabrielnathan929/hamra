# Setup

Instalar o NixOS e subir o Hamra numa máquina nova. É o caminho que eu uso:
ISO gráfica e instalador gráfico, sem particionamento manual.

## 1. Instalar o NixOS

1. Baixe a ISO gráfica do NixOS (GNOME) em <https://nixos.org/download>,
   grave num pendrive e dê boot por ele.
2. Instale pelo instalador gráfico. O desktop escolhido ali não importa — o
   Hamra instala o seu. Use o mesmo nome de usuário que vai declarar no
   Hamra (`hamra.users.userName`, default `gabrielnathan`) para aproveitar
   a home criada agora.
3. Reboot.

Do que a instalação gera, só o `hardware-configuration.nix` (discos, UUIDs,
mounts) sobrevive — é a identidade física da máquina. O `configuration.nix`
da instalação é descartado no passo seguinte.

## 2. Subir o Hamra

No primeiro boot, como o usuário criado na instalação:

```bash
sudo cp /etc/nixos/hardware-configuration.nix /tmp/
sudo rm -rf /etc/nixos && sudo mkdir /etc/nixos && sudo chown $(whoami): /etc/nixos
git clone https://github.com/gabrielnathan929/hamra /etc/nixos
cd /etc/nixos
```

Se o git não estiver instalado: `nix-shell -p git` antes do clone.

Copie o host mais parecido e troque o hardware-configuration:

```bash
cp -r hosts/samsung hosts/meu-pc
cp /tmp/hardware-configuration.nix hosts/meu-pc/
```

Ajuste os campos de identidade em `hosts/meu-pc/configuration.nix`:

```nix
hamra = {
  networking.hostname = "meu-pc";
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
- `theme.name` (opcional) — `dragon-ball` | `evangelion` | `resident-evil`

Tudo que diferir do perfil comum declara no host como delta
(ex.: `hamra.programs.optionals.services.samba = false;`).

Registre o host em `flake/hosts.nix`:

```nix
meu-pc = mkHost "meu-pc";
```

Pode reestruturar o `hardware-configuration.nix` (agrupar chaves), mas nunca
mude UUIDs nem dispositivos.

## 3. Segredo do Samba

O perfil comum liga o Samba (NAS). A senha dele fica criptografada em
`secrets/samba.yaml` e esta máquina precisa conseguir abri-la no boot — sem
isso o rebuild falha na ativação. Ou você registra a máquina, ou desliga o
Samba nela.

Registrando, com o assistente:

```bash
nix develop
./scripts/setup-nas.sh
```

Ele registra as chaves deste PC no `.sops.yaml`, grava a senha do NAS
criptografada para os PCs cadastrados e oferece o rebuild. Em máquina nova,
deixe-o criar/redefinir a senha — o arquivo precisa ser regravado com a
chave deste PC. Guia completo: [`docs/nas-iniciantes.md`](docs/nas-iniciantes.md).

Ou, se esta máquina não é NAS, no `configuration.nix` do host:

```nix
hamra.programs.optionals.services.samba = false;
```

## 4. Build e switch

```bash
sudo nixos-rebuild switch --flake .#meu-pc
```

O primeiro build demora — baixa o mundo. A partir daí os rebuilds são
incrementais. Reboot para cair no desktop do Hamra.

No dia a dia existem atalhos: `nix run .#deploy-<host>` (roda
`nix flake check` antes do switch) e `nix run .#build-<host>` (build sem
aplicar, resultado em `./result`). Eles só existem para os hosts listados
em `flake/apps.nix` — adicione o seu lá se quiser os atalhos.

## Validar

```bash
nix fmt
nix flake check
nix develop --command statix check .
nix develop --command deadnix .
```

O CI roda os mesmos checks — formatação, lint, avaliação e build de todos
os hosts — a cada push.
