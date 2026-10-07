# Hamra — Regras do Projeto

Hamra é uma **biblioteca de configuração** NixOS + Home Manager. Cada programa é um
"livro na prateleira": um arquivo autocontido que declara sua opção booleana e sua
implementação. Para usar, basta ativar o toggle em `hosts/<host>/configuration.nix`.

---

## Regras

### Sem comentários no código

Não use comentários em `.nix`, scripts e configs. O código deve se explicar sozinho:
nomes de arquivos, nomes de opções e `description` do `mkOption` cumprem esse papel.
Documentação pertence aos `.md` (`README.md`, `SETUP.md`, `docs/`, este arquivo).

### Camadas: NixOS vs Home

Define o que entra em cada camada:

| Camada | O que colocar | Exemplos |
|---|---|---|
| **NixOS** (`modules/nixos/programs/{core,optionals}/`) | Toggle modules de programas — instalação de pacote, daemon systemd, firewall, grupo de usuário, permissões de hardware | `core/cli/grim`, `optionals/games/steam`, `core/noctalia/gpu-screen-recorder` |
| **Home** (`modules/home/programs/`) | Apenas lógicas de configuração declarativa HM (`programs.foo`), config de shell/terminal/editor | zsh, foot, starship, aliases, neovim |

➡ Toda instalação de pacote vai no NixOS. Home é só para config.

### Categorias por forma do app

A categoria descreve **como o app se apresenta**, não o domínio de uso:

| Pasta | Critério | Exemplos |
|---|---|---|
| `gui/` | Abre janela | navegadores, vscode, discord, bitwarden, obsidian, kodi, nautilus |
| `tui/` | Interface dentro do terminal | btop, lazygit, yazi, lazydocker, cliamp |
| `cli/` | Linha de comando / toolchain | git, ripgrep, fd, jq, gcc, python3, rclone |
| `services/` | Daemon / integração do sistema | samba, docker, appimage, wayvnc, xdg, gtk |
| `media/` | Player e criação de mídia | mpv, spotify, spicetify, obs |
| `games/` | Jogos e launchers | steam, pcsx2, heroic, lutris |

Mantidas por especificidade: `core/noctalia/` (integração com o shell Noctalia) e
`core/scripts/` (scripts próprios do repo). Não crie subcategoria para 1 arquivo;
não crie gaveta genérica tipo "utility".

### Core vs Opcional

Toggle modules são categorizados em dois tiers:

| Tier | `default` | Critério |
|---|---|---|
| **Core** (infraestrutura) | `true` | Dependência de scripts, chamado em keybinds, utilitário recorrente do desktop, parte da base do ambiente. Exceções com `false`: `cli/git`, `gui/thunar` |
| **Opcional** (escolha pessoal) | `false` | Não quebra nada se desligado — agentes de IA, jogos, IDEs, players de mídia, ferramentas de segurança |

Programas core podem ser desligados explicitamente por quem quiser um ambiente mais enxuto.

### mise vs Nix

O usuário mantém ferramentas de dev em `latest` via **mise** (`core/cli/mise`)
e pode ter a mesma ferramenta instalada por toggle Nix ao mesmo tempo — não é
duplicata proibida, os contextos são diferentes. Precedência de PATH: no
shell interativo o hook do mise (`mise activate` via `enableZshIntegration`)
mantém os shims na frente, então `mise use -g` sempre vence o store do Nix;
fora do shell (daemons, desktop entries, serviços) só existe a versão Nix.
Se um host não quiser a versão mise de alguma ferramenta, basta não instalar
via mise — o toggle Nix serve como base/fallback.

### Apps por fonte (Nix, mise, flatpak, webapps)

O comando **`hamra-apps`** (toggle `core/scripts/apps`, default `true`) lista o que
está instalado e o que pode ser instalado, com a fonte de cada item:

- `hamra-apps` — tudo; `hamra-apps -v go` — filtrar por nome; `hamra-apps --help`
- Instalados via Nix: pacotes do NixOS + `home.packages` do Home Manager (lidos do
  manifest `/etc/hamra/apps.json`, gerado no build)
- Disponíveis via mise: `mise ls --json` + o catálogo declarado em `hamra.mise.tools`
- Flatpak: `flatpak list` (system e user) + os declarados em `hamra.flatpak.apps`

Apps podem ser pré-setados no Nix (pode ser usado junto do modo imperativo):

| Opção | O que faz | Formato |
|---|---|---|
| `hamra.mise.tools` | tools do mise (via HM `globalConfig`) | `{ go = "latest"; node = ["lts" "22"]; }` |
| `hamra.mise.env` | seção `[env]` do mise | `{ _.path = ["~/.opencode/bin"]; }` |
| `hamra.mise.settings` | seção `[settings]` do mise | `{ github_attestations = false; }` |
| `hamra.flatpak.apps` | instala via oneshot `hamra-flatpak` na ativação | `[ "app.dvd.DVDStyler" ]` |
| `hamra.webapps` | gera wrapper + `.desktop` de app web | `{ notion = { url = "..."; desktopName = "Notion"; }; }` |

As opções do mise exigem o toggle `core/cli/mise` ligado (assertion em build);
as flatpak e webapps exigem seus módulos. `hamra.webapps.<nome>.icon` exige
`iconHash`. O toggle `optionals/gui/notion` é um thin wrapper sobre
`hamra.webapps.notion`.

O HM escreve **um único** `~/.config/mise/config.toml` a partir de
`hamra.mise.{tools,env,settings}`. Como o arquivo vira symlink para o store,
não edite à mão: declaração imperativa e declarativa não convivem — escolha um
dos dois, ou o build falha com "Existing file would be clobbered".

Tools fora do registry padrão usam o backend completo como chave:
`"github:herdrdev/herdr" = "latest"`.

O `github_attestations = false` é workaround para o mise 2026.5.12 do nixpkgs,
que falha na verificação de attestations (bug de timestamp do Sigstore,
corrigido no 2026.10+). Sobe quando o input `nixpkgs` passar disso.

### Perfil comum dos hosts (`hosts/common/`)

Todo host importa `hosts/common` e declara apenas **deltas** (o que difere do padrão).
O common define env padrão e os optionals de uso pessoal — todos como `true`,
envolvidos em `lib.mkDefault` para qualquer host poder sobrescrever sem conflito.

- Toggle novo em uso em todo host → adicione `= true` no common.
- Host não quer algo do common → declare `= false` no `configuration.nix` dele
  (ex.: um host com `desktop.default = "gnome"` precisa de `wayvnc = false`,
  pois a assertion exige Hyprland/Sway).
- Host quer algo fora do common → declare `= true` nele.
- **Papel de host ≠ preferência pessoal:** `samba`, `wayvnc`, `tigervnc` dizem
  *quem a máquina é* (NAS, VNC server), não *o que você gosta de usar*. Eles
  ficam `false` no common (ou inexistentes lá) e ligam como delta só no host
  que desempenha o papel (ex.: `samsung` é o NAS → `services.samba = true`
  nele). Um host novo criado pelo `setup-nas.sh` NÃO deve virar NAS por
  acidente ao importar o common.

### Toggle module (NixOS)

Um arquivo por programa. Declara opção + implementação juntas. O `scanPaths` do
`default.nix` da categoria descobre automaticamente.

```nix
{config, lib, pkgs, ...}: let
  cfg = config.hamra.programs.optionals.games.steam;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.optionals.games.steam = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Steam.";
  };

  config.programs.steam = mkIf cfg {
    enable = true;
  };
}
```

- Core: `options.hamra.programs.core.<categoria>.<nome>`
- Opcional: `options.hamra.programs.optionals.<categoria>.<nome>`
- Usuário (Home Manager): `options.hamra.home.programs.<categoria>.<nome>`
- Nomes com hífen precisam de aspas: `"docker-compose"`
- O caminho da opção deve bater com a localização do arquivo:
  `optionals/tui/yazi.nix` → `optionals.tui.yazi`

### Nada de estrutura de pastas no código

Não confie em caminhos fixos. Use `scanPaths` para auto-import sempre que possível.
Se um módulo precisa importar outro, use caminho relativo ao arquivo atual.

### Portal XDG

Cada desktop define seu próprio portal no `compositor.nix` — cada desktop é
auto-suficiente. O toggle `core/services/xdg` cuida só de user dirs, MIME e gvfs.

- Hyprland → `xdg-desktop-portal-hyprland`
- Sway → `xdg-desktop-portal-wlr`
- Niri → `xdg-desktop-portal-gtk`

### Hardware

Opções de hardware (GPU, firmware, bluetooth, touchpad, brightness) são
declaradas em módulos específicos, não num `options.nix` central.

### Tema

Cada tema define wallpaper + profile icon para Noctalia e Silent SDDM.
O toggle `hamra.theme.name` troca tudo automaticamente. Tema default: `resident-evil`.

### Navegador padrão

O perfil comum define `browser = pkgs.chromium` (o default do módulo em
`envs/env.nix` é `pkgs.helium`). Para trocar num host:
`hamra.env.browser = pkgs.firefox;`

### Assertions em tempo de build

Validações em `core/assertions.nix`: bootloader, GPU, firmware, áudio, desktop e
display manager dentro dos ranges; tema existente na lista; locale com `.UTF-8`;
campos obrigatórios preenchidos; WayVNC só com Hyprland ou Sway.

### NAS / Samba

O toggle `hamra.programs.optionals.services.samba` transforma o host em NAS SMB
(3 shares: `shared`, `games`, `backups`). Pastas criadas via `systemd.tmpfiles.rules`.
Os shares têm **lixeira automática** (VFS `recycle`): arquivos apagados via SMB
vão para a pasta oculta `.trash` de cada share, guardando a estrutura e versões.
Limitações: não protege contra `rm` direto no servidor; é para-choque contra
acidente, não backup. Guia: seção 9 de `docs/nas-iniciantes.md`.

A senha Samba é gerenciada pelo **sops-nix**: segredo em `secrets/samba.yaml`
(criptografado) aplicado automaticamente pelo `system.activationScripts.sync-samba-password`
(o script usa `stringAfter ["setupSecrets"]` para rodar depois do sops-nix).
Setup de chaves e uso no cliente: ver `README.md`/seção NAS.

### Novo PC / novo usuário (assistente para leigos)

Para replicar o NAS em QUALQUER PC sem conhecer criptografia/NixOS, existe o
`scripts/setup-nas.sh` (instalado como comando `setup-nas` pelo toggle
`core/scripts/setup-nas`). Ele cria a estrutura do host, gera/registra chaves
no `.sops.yaml`, cria a senha própria do usuário em `secrets/samba.yaml`
(criptografada) e aplica o rebuild — explicando cada passo e como resolver
erros. O `configuration.nix` gerado herda do `hosts/common`. Modos: `--check`,
`--mostrar-senha`, `--reset-senha`, `--ajuda`.
Guia completo: `docs/nas-iniciantes.md`.

### Segredos (sops-nix)

- Segredos ficam **criptografados** em `secrets/*.yaml` no repositório.
- Chaves (edição + decriptação por host) ficam no `.sops.yaml` na raiz.
- Chave de edição: `~/.config/sops/age/keys.txt` (gerada com `age-keygen`).
- Chave de cada host: `cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age`
- Novo host com segredo → adicionar pubkey no `.sops.yaml` + `nix develop --command sops updatekeys secrets/<arquivo>`.
- Editar um segredo: `nix develop --command sops secrets/<arquivo>`.
- Nunca commitar chaves privadas nem valores em claro.

---

## CI e qualidade

O repositório tem três checks no GitHub Actions:

| Check | O que faz | Como evitar falha |
|---|---|---|
| Formatação | `alejandra --check .` | `nix fmt` antes de commitar |
| Avaliação | `nix flake check` | `nix flake check` localmente |
| Lint | `statix` + `deadnix` | `nix develop --command statix check . && nix develop --command deadnix .` |

### Dicas

1. **`nix fmt`** antes de todo commit
2. **Agrupe chaves repetidas:** prefira `boot = { initrd.availableKernelModules = [...]; kernelModules = [...]; };` a duas linhas soltas
3. **`hardware-configuration.nix`:** pode reestruturar (agrupar chaves), mas não mude UUIDs/dispositivos
4. **Argumentos vazios:** use `_:` em vez de `{ }:` quando a função não usa argumentos
5. **`inherit`:** prefira `inherit (nixpkgs) lib;` em vez de `lib = nixpkgs.lib;`

### Comandos úteis

| Comando | O que faz |
|---|---|
| `nix fmt` | Formata todos os `.nix` com alejandra |
| `nix develop` | Entra no devShell com ferramentas |
| `nix flake check` | Avalia a flake completa |
| `nix develop --command statix check .` | Roda o linter |
| `nix develop --command deadnix .` | Verifica código morto |
