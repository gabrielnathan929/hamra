# Hamra

Configuração pessoal de NixOS + Home Manager organizada como uma biblioteca de
módulos. A premissa é simples: **um programa, um arquivo**. Cada arquivo declara
sua própria opção booleana e sua implementação, e um scan automático os descobre
— sem imports manuais, sem registry central, sem um `configuration.nix` de mil
linhas.

Um host Hamra não descreve programas: descreve a **máquina** (hostname, GPU,
desktop) e as **exceções** ao seu perfil pessoal, que vive em
[`hosts/common/`](hosts/common/default.nix).

## Como o projeto pensa

**Um programa, um arquivo.** O arquivo de um toggle tem ~20 linhas e é autocontido:
quer saber como o Steam é instalado? Existe só um lugar no repo com essa resposta.
O caminho da opção replica a localização do arquivo — `optionals/tui/yazi.nix`
declara `hamra.programs.optionals.tui.yazi` — então encontrar é sempre trivial.

**Duas camadas, dois tiers.** Instalação de pacote e serviços de sistema ficam em
`modules/nixos/`; configuração declarativa de usuário (shell, editor, terminal)
fica em `modules/home/`. Dentro do NixOS, `core/` é a base da máquina
(`default = true` — desligue se quiser um ambiente enxuto) e `optionals/` é
escolha pessoal (`default = false` — ativados no perfil comum).

**Categorias pela forma do app.** `gui/` abre janela, `tui/` vive no terminal,
`cli/` é linha de comando, `services/` é daemon ou integração, `media/` toca ou
produz mídia, `games/` é jogo. A pasta responde "como é esse programa", não
"a que categoria de uso ele pertence" — a forma muda muito menos que o domínio.

**Hosts herdam, não copiam.** `hosts/common/` concentra o padrão pessoal (env
padrão + optionals em uso), protegido por `mkDefault`: qualquer host sobrescreve
qualquer valor declarando-o de volta. Um host novo sai em ~20 linhas.

**Erro cedo.** Combinações inválidas quebram o eval, não o boot: a assertion de
WayVNC recusa hosts fora de Hyprland/Sway com mensagem explicando o porquê;
conflitos de prioridade entre módulos também falham na avaliação.

## O que é — e o que não é

| | |
|---|---|
| ✅ **É** | Biblioteca de módulos declarativos; padrão pessoal versionado e reaproveitável entre máquinas; wrapper fino sobre NixOS + Home Manager idiomáticos |
| ❌ **Não é** | Ferramenta de provisionamento de disco; sistema de backup (a lixeira do Samba é para-choque, não protege de `rm`); abstração que esconde o NixOS |

## Estrutura

```
hosts/
├── common/                 # perfil pessoal: env padrão + optionals em uso
├── desktop/  vm/  gnome/  plasma/   # identidade + deltas

modules/
├── lib/                    # scanPaths (auto-import)
├── nixos/
│   ├── core/               # base da máquina — default = true
│   │   ├── cli/            #   grim, slurp, wl-clipboard, jq, eza, fd...
│   │   ├── gui/            #   mpv, imv, zathura, thunar
│   │   ├── tui/            #   btop, fzf, tmux, ncdu
│   │   ├── services/       #   xdg, gtk
│   │   ├── noctalia/       #   integração com o shell Noctalia
│   │   └── scripts/        #   setup-nas, hamra-apps
│   ├── programs/           # opt-in — default = false
│   │   ├── cli/            #   ripgrep, gcc, python3, rclone...
│   │   ├── gui/            #   navegadores, IDEs, comunicação, segurança
│   │   ├── tui/            #   lazygit, lazydocker, cliamp, yazi
│   │   ├── services/       #   samba (NAS), docker, appimage, wayvnc, tigervnc
│   │   ├── media/          #   spotify, spicetify, obs, kodi
│   │   ├── games/          #   steam, pcsx2, heroic, moonlight-qt
│   │   └── packaging/      #   flatpak, gnome-software
│   └── desktops/           # hyprland, sway, niri, gnome, plasma
└── home/                   # Home Manager — config de usuário
    ├── programs/           #   editors, shell, terminals, utils
    └── desktops/           #   hyprland, niri, sway (noctalia)
```

## Uso

```nix
# sistema (opt-in) — o padrão pessoal vive em hosts/common/
hamra.programs.optionals.<categoria>.<nome> = true;

# sistema (core — desligar algo da base)
hamra.programs.core.<categoria>.<nome> = false;

# usuário (Home Manager)
hamra.home.programs.<categoria>.<nome> = true;
```

O painel **NixDeck** do Noctalia (`Alt+Space`, ou `/nixdeck` no launcher)
lista os toggles de sistema com o **estado real do eval** e escreve o delta no
`configuration.nix` do host — sem catálogo central: o que existe é descoberto do
próprio flake. O plugin também cobre instalação/remoção de apps, chaves
SSH/GPG, flake update e tarefas de sistema; vive no
[community-plugins](https://github.com/gabrielnathan929/community-plugins).

Instalação passo a passo (ISO gráfica ou minimal), anatomia de um host e o
comportamento interno dos módulos: [`SETUP.md`](SETUP.md).
Regras de contribuição: [`AGENTS.md`](AGENTS.md).

### Apps por fonte

O comando `hamra-apps` (core, `core/scripts/apps.nix`) lista o que está
instalado em cada camada (Nix, mise, Flatpak, web apps) com a versão, marca o
que foi declarado mas ainda não instalado e consulta as versões disponíveis no
registro do mise:

```bash
hamra-apps              # lista agrupada por fonte (Nix, mise, Flatpak, web)
hamra-apps <termo>      # filtra por nome (ignora maiúsculas)
hamra-apps -v <tool>    # últimas versões do tool disponíveis no mise
```

As camadas além do Nix também se declaram em Nix (perfil comum):

```nix
hamra = {
  mise.tools = {
    node = "lts";
    python = ["3.12" "3.13"];
  };
  flatpak.apps = ["com.discordapp.Discord" "org.videolan.VLC"];
  webapps.notion = {
    url = "https://www.notion.so";
    desktopName = "Notion";
  };
};
```

- `hamra.mise.tools` escreve `~/.config/mise/config.toml` via Home Manager.
  No primeiro rebuild com tools declaradas, o config imperativo existente é
  movido para backup pela ativação — migre antes o que quiser preservar.
- `hamra.flatpak.apps` instala os IDs do Flathub no serviço systemd
  `hamra-flatpak`, pulando o que já existe (instalação system ou user).
- `hamra.webapps.<nome>` gera wrapper + desktop entry (ícone opcional via
  `icon` + `iconHash`) que abrem o site em janela própria no navegador padrão.
  O `notion.nix` é só um toggle por cima desse mecanismo.

## Desenvolvimento

```bash
nix fmt                     # alejandra
nix flake check             # avalia os 4 hosts + assertions
nix develop --command statix check . && nix develop --command deadnix .
nix run .#build-<host>      # build sem aplicar
nix run .#deploy-<host>     # flake check + switch
```

O CI roda formatação, lint e build dos 4 hosts a cada push.

## Roadmap

- Checagem automática de "caminho da opção = localização do arquivo" no CI
- Pré-commit rodando `nix flake check` nos hosts afetados
- Rigor de auditabilidade dos módulos Home igual ao dos módulos NixOS

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
| [community-plugins](https://github.com/gabrielnathan929/community-plugins) | Fork com plugins extras para Noctalia: `myanimelist`, `nixdeck` |
| [color_picker](https://github.com/oldirtty/color_picker) | Plugin seletor de cor para Noctalia |
| [SilentSDDM](https://github.com/gabrielnathan929/SilentSDDM) | Fork do tema Silent SDDM |
| [sops-nix](https://github.com/Mic92/sops-nix) | Gestão de segredos |

Plugins Noctalia ativos: `wallhaven`, `mpvpaper`, `myanimelist`,
`nixdeck`, `notes`, `timer`, `bongocat`, `translator`, `screen_recorder`,
`color_picker`.

## Agradecimentos

- Comunidade NixOS e nix-community pelo ecossistema.
- Mantenedores do Noctalia pelo shell/desktop Wayland.
- Desenvolvedores de todos os projetos listados acima.
