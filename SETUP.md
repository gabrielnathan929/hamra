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

Depois de gerar o hardware config, registre o host em `flake/hosts.nix` e crie o `configuration.nix` baseando-se em um existente.

## Toggles

```nix
# sistema (opt-in)
hamra.programs.<categoria>.<nome> = true;

# sistema (core — desligar)
hamra.programs.core.<subcategoria>.<nome> = false;

# usuário (Home Manager)
hamra.home.programs.<categoria>.<nome> = true;
```

**Core** abrange infraestrutura do desktop e utilitários básicos: terminal-tools, desktop (GTK, XDG, screenshot), media, monitoring, nix-tools, scripts de setup. Todos com `default = true` — dispensam declaração no host a menos que se queira desativá-los.

## Ambiente

```nix
hamra.env = {
  editor    = pkgs.neovim;
  browser   = pkgs.helium;
  terminal  = pkgs.foot;
  filemanager = pkgs.thunar;
};
```

Define as variáveis de ambiente por host. Os pacotes são instalados automaticamente e expostos como `$EDITOR`, `$BROWSER`, etc.

## Validações

Assertions em tempo de build em `modules/nixos/core/assertions.nix` previnem combinações inválidas: WayVNC com Niri, tema inexistente, locale sem `.UTF-8` ou campos obrigatórios vazios.

## Comandos

```bash
nix run .#deploy-desktop    # check + switch
nix run .#build-desktop     # só build
nix run .#deploy-vm
nix run .#build-vm
nix develop                 # dev shell (alejandra, statix, deadnix)
nix fmt                     # formata tudo
nix flake check             # valida a flake
```
