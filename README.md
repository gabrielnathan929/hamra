# Hamra

## Motivação

O `configuration.nix` cresce rápido e vira uma parede de texto. Hamra resolve
isso com um módulo por programa: cada um declara sua própria opção `bool` e
implementação. O scan automático descobre os arquivos — sem imports manuais.

Cada host importa o **perfil comum** (`hosts/common/`) e declara apenas os
deltas: o que ele tem de diferente do padrão.

Toggle modules se dividem em dois tiers:

- **`core/`** — infraestrutura do desktop e utilitários básicos. `default = true`.
  Dispensa declaração no host a menos que queira desligar.
- **`optionals/`** — opt-in. `default = false`. Só ativam com declaração explícita
  (o comum fica no `hosts/common/`).

## Estrutura

```
hosts/
├── common/                 # perfil compartilhado: env padrão + optionals em uso
├── desktop/                # host: identidade (hostname, gpu, desktop) + deltas
├── vm/
├── gnome/
└── plasma/

modules/
├── lib/                    # scanPaths (auto-import)
├── nixos/                  # sistema
│   ├── core/               # infraestrutura base — default = true
│   │   ├── cli/            #   grim, slurp, wl-clipboard, jq, eza, fd...
│   │   ├── gui/            #   mpv, imv, zathura, thunar
│   │   ├── tui/            #   btop, fzf, tmux, yazi, gum, ncdu
│   │   ├── services/       #   xdg, gtk
│   │   ├── noctalia/       #   integração com o shell Noctalia
│   │   └── scripts/        #   setup-gpg, setup-ssh, setup-nas, flatpak
│   ├── programs/           # opt-in — default = false
│   │   ├── cli/            #   ripgrep, gcc, python3, rclone...
│   │   ├── gui/            #   navegadores, IDEs, comunicação, segurança
│   │   ├── tui/            #   lazygit, lazydocker, opencode, codex, antigravity
│   │   ├── services/       #   samba (NAS), docker, appimage, wayvnc, tigervnc
│   │   ├── media/          #   spotify, spicetify, obs, kodi
│   │   ├── games/          #   steam, pcsx2, heroic, moonlight-qt
│   │   └── packaging/      #   flatpak, gnome-software
│   └── desktops/           # desktops (hyprland, sway, niri, gnome, plasma)
└── home/                   # Home Manager — config de usuário
    ├── programs/
    │   ├── editors/        #   neovim (plugins, extraConfig)
    │   ├── shell/          #   zsh, starship, aliases
    │   ├── terminals/      #   foot, kitty, alacritty
    │   └── utils/          #   fastfetch (config)
    └── desktops/           #   hyprland, niri, sway (noctalia)
```

Categorias descrevem a **forma do app** (como ele se apresenta), não o domínio:
`gui/` abre janela, `tui/` vive no terminal, `cli/` é linha de comando,
`services/` é daemon/integração, `media/` é player/criação, `games/` é jogo.

## Toggles

```nix
# sistema (opt-in) — o padrão do usuário vive em hosts/common/
hamra.programs.optionals.<categoria>.<nome> = true;

# sistema (core — desligar algo da base)
hamra.programs.core.<categoria>.<nome> = false;

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
