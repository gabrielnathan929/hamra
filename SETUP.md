# Setup

Como configurar o Hamra em outra máquina.

## Instalação do zero

```bash
# backup da config atual
sudo cp -r /etc/nixos /etc/nixos.bak

# clonar
sudo rm -rf /etc/nixos && sudo mkdir /etc/nixos
nix-shell -p git
sudo git clone https://github.com/gabrielnathan929/hamra .
sudo cp /etc/nixos.bak/hardware-configuration.nix hosts/desktop/hardware-configuration.nix

# aplicar
sudo nixos-rebuild switch --flake .#desktop
```

O `hardware-configuration.nix` é único de cada máquina.

## Novo host

```bash
mkdir hosts/novo-host
sudo nixos-generate-config --show-hardware-config > hosts/novo-host/hardware-configuration.nix
```

Depois registrar o host em `flake/hosts.nix` e criar o `configuration.nix` baseado em um existente.

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

## Toggles

```nix
# sistema
hamra.programs.<categoria>.<nome> = true;

# usuario
hamra.home.programs.<categoria>.<nome> = true;
```

## Assertions

Validações em tempo de build em `modules/nixos/core/assertions.nix`. Impedem combinações inválidas como WayVNC com Niri, tema inexistente, locale sem `.UTF-8`, ou campos obrigatórios vazios.
