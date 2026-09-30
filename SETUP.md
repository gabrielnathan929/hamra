# Setup

Como configurar o Hamra em uma nova máquina.

## Instalação do zero

```bash
# backup da configuração atual
sudo cp -r /etc/nixos /etc/nixos.bak

# clonar o repositório
sudo rm -rf /etc/nixos && sudo mkdir /etc/nixos
nix-shell -p git
sudo git clone https://github.com/gabrielnathan929/hamra .
sudo cp /etc/nixos.bak/hardware-configuration.nix hosts/desktop/hardware-configuration.nix

# aplicar
sudo nixos-rebuild switch --flake .#desktop
```

O `hardware-configuration.nix` é específico de cada máquina e deve ser preservado.

## Novo host

```bash
mkdir hosts/novo-host
sudo nixos-generate-config --show-hardware-config > hosts/novo-host/hardware-configuration.nix
```

Registre o host em `flake/hosts.nix` e crie um `configuration.nix` no formato
enxuto (identidade + deltas):

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
    networking.hostname = "novo-host";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "hyprland";
  };
}
```

O host herda tudo de `hosts/common/` (env padrão + optionals de uso pessoal).
Para desligar algo do common: `hamra.programs.optionals.<categoria>.<nome> = false;`.
Para acrescentar algo fora do common: `= true;` no host.

## Toggles

```nix
# sistema (opt-in) — padrão do usuário vive em hosts/common/
hamra.programs.optionals.<categoria>.<nome> = true;

# sistema (core — desligar algo da base)
hamra.programs.core.<categoria>.<nome> = false;

# usuário (Home Manager)
hamra.home.programs.<categoria>.<nome> = true;
```

**Core** (`modules/nixos/programs/core/`) é a infraestrutura base, com
`default = true` — dispensa declaração. Categorias por forma do app:
`cli/` (grim, jq, eza...), `gui/` (mpv, zathura, thunar*), `tui/` (btop, fzf,
tmux...), `services/` (xdg, gtk), `noctalia/` e `scripts/` (*thunar e git são
as únicas exceções com `default = true` após esta mudança: git `true`; thunar
permanece `false`).

**Optionals** (`modules/nixos/programs/optionals/`) são `default = false` e
ativados pelo `hosts/common/`: `gui/` (navegadores, IDEs, comunicação,
segurança), `tui/` (lazygit, opencode, codex, antigravity, yazi), `cli/`
(toolchains), `services/` (samba, docker, appimage, vnc), `media/` (spotify,
obs, kodi), `games/` e `packaging/`.

## Ambiente

```nix
hamra.env = {
  editor    = pkgs.neovim;
  browser   = pkgs.chromium;
  terminal  = pkgs.foot;
  filemanager = pkgs.nautilus;
};
```

O common já define esse padrão; hosts podem sobrescrever campo a campo. Os
pacotes são instalados automaticamente e expostos como `$EDITOR`, `$BROWSER`, etc.

## Validações

Assertions em tempo de build em `modules/nixos/core/assertions.nix` previnem
combinações inválidas: WayVNC só com Hyprland/Sway (por isso gnome e plasma
declaram `wayvnc = false`), tema inexistente, locale sem `.UTF-8` ou campos
obrigatórios vazios.

## Comandos

```bash
nix run .#deploy-desktop    # check + switch
nix run .#build-desktop     # só build
nix run .#deploy-vm         # idem para vm, gnome e plasma
nix run .#build-vm
nix develop                 # dev shell (alejandra, statix, deadnix)
nix fmt                     # formata tudo
nix flake check             # valida a flake
```
