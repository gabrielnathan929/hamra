# Hamra

## Motivação

O `configuration.nix` cresce rápido e vira uma parede de texto. Hamra resolve
isso com um módulo por programa: cada um declara sua própria opção `bool` e
implementação. O scan automático descobre os arquivos — sem imports manuais.

Toggle modules se dividem em dois tiers:

- **`core/`** — infraestrutura do desktop e utilitários básicos. `default = true`.
  Dispensa declaração no host a menos que queira desligar.
- **`programs/`** — opt-in. `default = false`. Só ativam com declaração explícita.

## Estrutura

```
modules/
├── nixos/                  # sistema
│   ├── core/               # infraestrutura base — default = true
│   │   ├── desktop/        #   tema GTK, XDG, screenshot, clipboard, OCR
│   │   ├── media/          #   visualizador de imagem, vídeo, PDF
│   │   ├── monitoring/     #   btop, fastfetch
│   │   ├── nix-tools/      #   nom, nix-search
│   │   ├── scripts/        #   setup-gpg, setup-ssh, flatpak
│   │   └── terminal-tools/ #   curl, eza, fzf, gum, jq, tmux, tree
│   ├── programs/           # opt-in — default = false
│   │   ├── audio/          #   spotify, spicetify
│   │   ├── browsers/       #   helium, chromium, firefox, google-chrome
│   │   ├── development/    #   git, docker, gcc, ripgrep
│   │   ├── games/          #   steam, pcsx2, heroic
│   │   ├── ides/           #   vscode, intellij, pycharm
│   │   ├── packaging/      #   flatpak, gnome-software
│   │   ├── productivity/   #   obsidian, libreoffice
│   │   ├── remote/         #   remmina, tigervnc
│   │   ├── security/       #   bitwarden, ente-auth
│   │   ├── services/       #   wayvnc, samba (NAS)
│   │   ├── utility/        #   localsend, obs-studio
│   │   └── virtualisation/ #   boxes, virt-manager
│   └── desktop/            # desktops (hyprland, sway, niri)
└── home/                   # Home Manager — config de usuário
    ├── programs/
    │   ├── editors/        #   neovim (plugins, extraConfig)
    │   ├── shell/          #   zsh, starship, aliases
    │   ├── terminals/      #   foot, kitty, alacritty
    │   └── utils/          #   fastfetch (config)
    └── scripts/            #   scripts de usuário
```

## Toggles

```nix
# sistema (opt-in)
hamra.programs.<categoria>.<nome> = true;

# sistema (core — desligar)
hamra.programs.core.<subcategoria>.<nome> = false;

# usuário (Home Manager)
hamra.home.programs.<categoria>.<nome> = true;
```

## Projetos de terceiros

Este repositório integra e redistribui configurações de projetos externos.
Todos os direitos pertencem aos seus respectivos autores.

| Projeto | Descrição |
|---|---|
| [nixpkgs](https://github.com/NixOS/nixpkgs) | Distribuição e pacotes |
| [home-manager](https://github.com/nix-community/home-manager) | Gerenciamento de perfil de usuário |
| [Noctalia](https://github.com/noctalia-dev/noctalia) | Shell/desktop Wayland modular |
| [spicetify-nix](https://github.com/Gerg-L/spicetify-nix) | Módulo Nix para Spicetify |
| [Helium](https://github.com/oxcl/nix-flake-helium-browser) | Navegador baseado em Chromium |
| [alejandra](https://github.com/kamadorueda/alejandra) | Formatador de Nix |
| [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) | Conjunto de ícones |
| [Bibata](https://github.com/ful1e5/Bibata_Cursor) | Tema de cursor |
| [official-plugins](https://github.com/gabrielnathan929/official-plugins) | Fork com plugins oficiais ajustados: `wallhaven`, `mpvpaper` |
| [community-plugins](https://github.com/gabrielnathan929/community-plugins) | Fork com plugins extras para Noctalia: `myanimelist` |
| [color_picker](https://github.com/oldirtty/color_picker) | Plugin seletor de cor para Noctalia |
| [SilentSDDM](https://github.com/gabrielnathan929/SilentSDDM) | Fork do tema Silent SDDM |
| [sops-nix](https://github.com/Mic92/sops-nix) | Gestão de segredos (samba, futuras credenciais) |

Plugins Noctalia ativos: `wallhaven`, `mpvpaper`, `myanimelist`, `notes`,
`timer`, `bongocat`, `translator`, `screen_recorder`, `color_picker`.

## NAS / Samba

Ative `hamra.programs.optionals.services.samba = true` no host e ele vira um NAS
SMB com 3 shares (`shared`, `games`, `backups`), acesso por usuário/senha e
firewall limitado à rede local. Arquivos apagados via rede caem numa **lixeira**
(pasta oculta `.trash` de cada share) em vez de sumirem. A senha é gerenciada
por sops-nix (`secrets/samba.yaml`), aplicada sozinha a cada rebuild.

Setup de chaves e montagem no cliente: ver `AGENTS.md` (seção Segredos).

## Agradecimentos

- Comunidade NixOS e nix-community pelo ecossistema.
- Mantenedores do Noctalia pelo shell/desktop Wayland.
- Desenvolvedores de todos os projetos listados acima.
- Contribuidores que mantêm pacotes, documentação e infraestrutura do
  ecossistema Nix.

### Novo PC? Não sabe nada de criptografia? Use o assistente

```bash
cd /etc/nixos
nix develop
./scripts/setup-nas.sh          # cria o host, chaves e a SUA senha do NAS
```

Ele faz todo o processo de segredos e registro de host explicando cada
passo, e trata erros e senhas esquecidas (`--mostrar-senha`, `--reset-senha`,
`--check`). Guia completo para leigos: `docs/nas-iniciantes.md`.
