# Hamra

Configuração NixOS + Home Manager das minhas máquinas, escrita como uma
biblioteca de toggles: cada programa é um arquivo que declara a própria
opção booleana e a própria implementação. Montei assim para saber exatamente
o que está instalado, entender cada componente direto no código e trocar
qualquer peça — GPU, desktop, navegador, tema — mexendo numa linha. Não é
distro e não tenta configurar tudo: o que está aqui é o quanto me basta.

## Como funciona

Um host (`hosts/<nome>/configuration.nix`) descreve só a máquina e as
exceções ao meu perfil comum, que vive em `hosts/common/` envolvido em
`mkDefault` — qualquer host sobrescreve qualquer valor declarando de volta.
O `desktop` inteiro é isto:

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
    networking.hostname = "desktop";

    hardware = {
      gpu = "intel";
      firmware = "uefi";
    };

    desktop.default = "hyprland";
  };
}
```

Três famílias de toggle:

- `hamra.programs.core.<categoria>.<nome>` — base da máquina, `default = true`.
  Boot, rede com firewall, locale, segurança (polkit, keyring, GnuPG, SSH) e
  utilitários recorrentes. Desligue por toggle para um ambiente mais enxuto.
- `hamra.programs.optionals.<categoria>.<nome>` — escolha pessoal,
  `default = false`, ligada no perfil comum: `optionals.gui.vscode`,
  `optionals.games.steam`, `optionals.services.docker`... Host não quer algo
  do common? Declara `= false` nele.
- `hamra.home.programs.<categoria>.<nome>` — Home Manager, configuração de
  usuário (editor, shell, terminal). Instalação de pacote fica sempre na
  camada NixOS; a camada home é só config.

A categoria descreve a forma do app, não o domínio: `gui/` abre janela,
`tui/` vive no terminal, `cli/` é linha de comando, `services/` é daemon,
`media/` toca ou produz mídia, `games/` é jogo (em optionals existe também
`packaging/`). O caminho da opção replica o caminho do arquivo:
`optionals/tui/lazygit.nix` declara `hamra.programs.optionals.tui.lazygit` —
encontrar é sempre trivial.

Combinações inválidas quebram o eval, não o boot: `core/assertions.nix`
recusa GPU inexistente, tema errado, WayVNC fora de Hyprland/Sway e afins
com mensagem explicando o motivo.

## O que está instalado

O comando `hamra-apps` lista tudo, por fonte:

```bash
hamra-apps              # Nix, mise, Flatpak e web apps, com versão
hamra-apps <termo>      # filtra por nome (ignora maiúsculas)
hamra-apps -v <tool>    # versões do tool disponíveis no registro do mise
```

A parte Nix sai de um manifest (`/etc/hamra/apps.json`) gerado no build a
partir dos próprios módulos — não existe lista manual para desatualizar. O
que foi declarado mas ainda não instalou aparece marcado (mise e Flatpak).

## Apps fora do Nix

| Opção | O que faz |
|---|---|
| `hamra.mise.tools` | tools do mise no `~/.config/mise/config.toml` (via HM) |
| `hamra.flatpak.apps` | instala os IDs do Flathub no serviço `hamra-flatpak` |
| `hamra.webapps` | wrapper + `.desktop` que abrem o site em janela própria |

Cada uma exige o módulo correspondente ligado (assertion em build). Quem usa
o config do mise imperativo declara as tools lá, não em Nix. Exemplo de web
app:

```nix
hamra.webapps.notion = {
  url = "https://www.notion.so";
  desktopName = "Notion";
};
```

(`optionals/gui/notion.nix` é exatamente esse bloco atrás de um toggle.)

## Adicionar um app novo

Um arquivo, um toggle. Exemplo real —
`modules/nixos/programs/optionals/tui/lazygit.nix`:

```nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.programs.optionals.tui.lazygit;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.tui.lazygit = mkOption {
    type = types.bool;
    default = false;
    description = "Enable lazygit (TUI for git).";
  };

  config.environment.systemPackages = mkIf cfg (with pkgs; [lazygit]);
}
```

Pacote na camada NixOS, config de usuário em `modules/home/`. O `scanPaths`
descobre o arquivo sozinho, sem import manual. Liga em `hosts/common/` se
vale para toda máquina, ou no host. Pacote avulso sem módulo:
`hamra.packages.extra = [pkgs.foo];`.

## Tema

`hamra.theme.name` troca wallpaper, ícone de perfil e vídeos de uma vez — o
ícone alimenta o Silent SDDM, o wallpaper o shell. Temas: `dragon-ball`,
`evangelion`, `resident-evil` (cada um é uma pasta em
`modules/nixos/core/theme/themes/`). Ícone de janela (Papirus) e cursor
(Bibata) são fixos do tema base.

## Comandos

| Comando | O que faz |
|---|---|
| `nix fmt` | formata tudo (alejandra) |
| `nix flake check` | avalia todos os hosts + assertions |
| `nix develop` | shell com statix, deadnix, sops, age, ssh-to-age |
| `nix run .#build-<host>` | build sem aplicar (salva em `./result`) |
| `nix run .#deploy-<host>` | `nix flake check` + `nixos-rebuild switch` |
| `hamra-keybinds [contexto]` | atalhos do WM ativo, `tmux`, `herdr` ou `all` |

No desktop, `SUPER+K` abre os atalhos do compositor em busca interativa;
`SUPER+CTRL+K` e `SUPER+ALT+K` trazem os menus do Herdr e do Tmux. Dentro do
tmux, `Prefix + ?` abre o mesmo painel num popup.

Hosts registrados: `desktop`, `vm`, `gnome`, `plasma`. O CI roda formatação,
lint (`statix` + `deadnix`), avaliação e build de todos os hosts a cada push.

## Leitura

- [`SETUP.md`](SETUP.md) — instalar o NixOS e subir o Hamra numa máquina nova
- [`docs/nas-iniciantes.md`](docs/nas-iniciantes.md) — montar o NAS (Samba + segredos) em qualquer PC
- [`AGENTS.md`](AGENTS.md) — regras do repo: camadas, categorias, toggle module
