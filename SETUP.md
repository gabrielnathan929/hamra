# Setup

Como instalar o NixOS e subir o Hamra em uma máquina — e como os módulos se
comportam por baixo dos panos.

## 1. Instalar o NixOS

O Hamra **substitui** o `configuration.nix` gerado pela instalação, mas o
`hardware-configuration.nix` (discos, UUIDs, mounts) vem da máquina e é
preservado. Escolha um dos caminhos:

### ISO gráfica

1. Baixe a ISO gráfica do NixOS, grave no pendrive e boote.
2. Rode o instalador (Calamares) com qualquer desktop — o desktop final é o
   do Hamra, não o da instalação.
3. Ao terminar, **não reboot ainda**: monte o disco instalado e copie o
   `hardware-configuration.nix` gerado:

```bash
mount /dev/disk/by-label/nixos /mnt   # ajuste o label
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/
```

### ISO minimal

1. Baixe a ISO minimal, boote e entre como `nixos` (sem senha).
2. Particione (exemplo UEFI simples):

```bash
sudo -i
partitioned=/dev/vda   # ajuste
sgdisk --zap-all $partitioned
sgdisk -n 1:0:+1G -t 1:ef00 -n 2:0:0 -t 2:8300 $partitioned
mkfs.fat -F32 -n BOOT ${partitioned}1
mkfs.ext4 -L nixos ${partitioned}2
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot && mount /dev/disk/by-label/BOOT /mnt/boot
nixos-generate-config --root /mnt
```

3. Instale o sistema base e copie o hardware config gerado:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/
nixos-install    # pede senha do root; reboot ao terminar
```

A diferença prática: a ISO gráfica faz o particionamento para você; a minimal
te dá controle total (criptografia LUKS, btrfs, swap — o que você configurar
vira o `hardware-configuration.nix`). O Hamra funciona igual nos dois casos.

## 2. Subir o Hamra

Após o reboot (ou no chroot da instalação):

```bash
sudo rm -rf /etc/nixos && sudo mkdir /etc/nixos && sudo chown $(whoami): /etc/nixos
git clone https://github.com/gabrielnathan929/hamra /etc/nixos
cd /etc/nixos

cp /tmp/hardware-configuration.nix hosts/<host>/hardware-configuration.nix
nixos-rebuild switch --flake .#<host>
```

O `hardware-configuration.nix` é a identidade física da máquina: pode
reestruturar (agrupar chaves), mas nunca mude UUIDs nem dispositivos.

## 3. Anatomia de um host

```nix
_: {
  imports = [
    ./hardware-configuration.nix
    ../common
    ../../modules/nixos/core
    ../../modules/nixos/programs
    ../../modules/nixos/desktops
  ];

  hamra = {
    networking.hostname = "vm";

    hardware = {
      gpu = "virtio";
      firmware = "uefi";
    };

    desktop.default = "sway";

    programs.optionals.services.wayvnc = true;
  };
}
```

- `../common` — perfil compartilhado: env padrão + todos os optionals de uso
  pessoal como `true` (sob `mkDefault`).
- Os outros três imports trazem a árvore inteira de módulos — sempre.
- O corpo do host é **identidade** (hostname, GPU, firmware, desktop) +
  **deltas** (exceções ao common, como `wayvnc = false` em gnome/plasma).

## 4. Comportamento dos módulos

### Auto-descoberta (scanPaths)

Cada pasta tem um `default.nix` que importa subpastas e arquivos `.nix`
vizinhos. A árvore inteira é **importada sempre** — importar não é ativar.
Importante: se uma pasta nova for criada sem `default.nix`, o eval quebra;
se um arquivo novo aparecer, é descoberto sozinho.

### Toggle = opção + implementação

```nix
options.hamra.programs.optionals.tui.yazi = mkOption {
  type = types.bool;
  default = false;
  ...
};

config.environment.systemPackages = mkIf cfg (with pkgs; [yazi]);
```

O `mkIf` guarda a **config**, não a declaração: toggle `false` não instala
nada, mas a opção continua existindo para qualquer host declarar.

### Tiers e defaults

`core/` = `default = true` (base da máquina; desligue por toggle).
`optionals/` = `default = false` (ativados no `hosts/common/`).
Exceção histórica hoje: nenhum — o `git` virou `true`.

### Prioridades (por que `mkDefault` no common)

Opção definida em dois lugares com valor plain = **erro de conflito**.
Por isso o common envolve tudo em `lib.mkDefault` (prioridade 1000): o host
pode declarar o mesmo caminho com valor plain (100) e vence sem barulho.
Entre dois `mkDefault`, ainda há conflito — por isso `virt-manager` usa
valores plain e `boxes` usa `mkDefault` nas opções compartilhadas do
libvirtd, permitindo os dois ligados.

### Caminho da opção = localização do arquivo

`optionals/tui/yazi.nix` declara `optionals.tui.yazi`. A categoria do caminho
é a pasta. Nomes com hífen levam aspas: `services."docker-compose"`.

### Assertions

`modules/nixos/core/assertions.nix` falha o **eval** (antes de buildar) em
combinações inválidas — ex.: `wayvnc = true` fora de hyprland/sway, tema
inexistente, locale sem `.UTF-8`. Erro cedo com mensagem explicando o motivo.

### Passagem NixOS → Home Manager

O host injeta `extraSpecialArgs` no Home Manager (`env`, `displays`,
`keyboard`, `desktop`...). É assim que um módulo home (ex.: keybinds do
Hyprland) usa o navegador/terminal escolhidos no módulo NixOS — fonte única
de verdade.

## 5. Novo host

```bash
mkdir hosts/novo-host
sudo nixos-generate-config --show-hardware-config > hosts/novo-host/hardware-configuration.nix
```

Registre em `flake/hosts.nix` (`novo-host = mkHost "novo-host";`) e escreva o
`configuration.nix` no formato da seção 3. Existe também o assistente
`./scripts/setup-nas.sh` para o fluxo de NAS (host + chaves sops + senha).

## 6. Validação

```bash
nix fmt                     # alejandra
nix flake check             # avalia os 4 hosts + assertions
nix develop --command statix check .
nix develop --command deadnix .
nix run .#build-<host>      # build sem aplicar
nix run .#deploy-<host>     # flake check + switch
```

O CI roda formatação, lint e build dos 4 hosts a cada push.
