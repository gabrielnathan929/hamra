# Hamra — Regras do Projeto

Hamra é uma **biblioteca de configuração** NixOS + Home Manager. Cada programa é um
"livro na prateleira": um arquivo autocontido que declara sua opção booleana e sua
implementação. Para usar, basta ativar o toggle em `hosts/<host>/configuration.nix`.

---

## Regras

### Camadas: NixOS vs Home

Define o que entra em cada camada:

| Camada | O que colocar | Exemplos |
|---|---|---|
| **NixOS** (`modules/nixos/programs/`) | Daemon systemd, firewall, security wrapper/capability, grupo de usuário, `permittedInsecurePackages`, gerenciador de pacote do sistema, hardware/kernel | Docker, libvirtd, Steam (firewall), btop (cap_perfmon), Flatpak system service |
| **Home** (`modules/home/programs/`) | Instalação de pacote no perfil, config declarativa HM (`programs.foo`), config de shell/terminal/editor, scripts do usuário, XDG dirs/MIME, tema GTK | spotify, zsh, foot, git config, setup-gpg, aliases, gtk themes |
| **Split (ambos)** | Quando o programa precisa das duas camadas. A instalação do pacote fica no Home; a config de sistema fica no NixOS. | obsidian (NixOS → electron permissão, Home → pacote), btop (NixOS → wrapper, Home → pacote) |

➡ Se o programa SÓ instala um pacote e não precisa de nada do sistema → **Home**. Se mexe em service, segurança ou hardware → **NixOS**.

### Core vs Opcional

Toggle modules são categorizados em dois tiers:

| Tier | `default` | Critério |
|---|---|---|
| **Core** (infraestrutura) | `true` | Dependência de scripts, chamado em keybinds, utilitário recorrente do desktop, parte da base do ambiente |
| **Opcional** (escolha pessoal) | `false` | Não quebra nada se desligado — jogos, IDEs, players de mídia, ferramentas de segurança |

Programas core podem ser desligados explicitamente por quem quiser um ambiente mais enxuto.

### Toggle module (NixOS)

Um arquivo por programa. Declara opção + implementação juntas. O `scanPaths` do
`default.nix` da categoria descobre automaticamente.

```nix
{config, lib, pkgs, ...}: let
  cfg = config.hamra.programs.games.steam;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.programs.games.steam = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Steam.";
  };

  config.programs.steam = mkIf cfg {
    enable = true;
  };
}
```

- Sistema: `options.hamra.programs.<categoria>.<nome>`
- Usuário (Home Manager): `options.hamra.home.programs.<categoria>.<nome>`
- Nomes com hífen precisam de aspas: `"docker-compose"`

### Nada de estrutura de pastas no código

Não confie em caminhos fixos. Use `scanPaths` para auto-import sempre que possível.
Se um módulo precisa importar outro, use caminho relativo ao arquivo atual.

### Portal XDG

Cada desktop define seu próprio portal no `compositor.nix`. O módulo `services/xdg/`
não existe mais — cada desktop é auto-suficiente.

- Hyprland → `xdg-desktop-portal-hyprland`
- Sway → `xdg-desktop-portal-wlr`
- Niri → `xdg-desktop-portal-gtk`

### Hardware

Opções de hardware (GPU, firmware, bluetooth, touchpad, brightness) são
declaradas em módulos específicos, não num `options.nix` central.

### Tema

Cada tema define wallpaper + profile icon para Noctalia e Silent SDDM.
O toggle `hamra.theme.name` troca tudo automaticamente.

### Navegador padrão

`$BROWSER` aponta para `pkgs.helium` por padrão (definido em `envs/env.nix`).
Para trocar num host: `hamra.env.browser = pkgs.firefox;`

### Assertions em tempo de build

Validações em `core/assertions.nix`: bootloader, GPU, firmware, áudio, desktop e
display manager dentro dos ranges; tema existente na lista; locale com `.UTF-8`;
campos obrigatórios preenchidos; WayVNC só com Hyprland ou Sway.

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
