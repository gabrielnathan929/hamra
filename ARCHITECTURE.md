# Arquitetura

## De onde vem a configuração que inicializa esta máquina?

Resposta curta: o sistema ativo é o closure do último
`nixos-rebuild switch --flake <checkout>#<host>`. O **repositório Git é a
fonte de verdade**; `/etc/nixos` não tem papel especial (numa máquina já
rodando Hamra ele nem precisa existir). Cada máquina aponta o rebuild para o
seu checkout — nunca confie no default sem `--flake`.

A cadeia completa:

```
flake.nix + flake.lock (inputs pinados, nixos-26.05)
  -> mkHost (flake/hosts.nix; specialArgs: self, inputs, hostName, hamraLib)
    -> hosts/<maquina>/configuration.nix    (identidade + deltas do padrão)
    -> hosts/<maquina>/hardware-configuration.nix (identidade física; gerado na máquina)
    -> hosts/common/default.nix             (perfil compartilhado, tudo em mkDefault)
    -> modules/nixos/{core,programs,desktops} (auto-import via hamraLib.scanPaths)
    -> home-manager (extraSpecialArgs: tema, teclado, desktop, env...)
    -> assertions (desktop, GPU, tema, papel de host inválidos quebram o eval)
  -> closure -> switch -> /run/current-system
```

O nome do sistema ativo segue `hamra.networking.hostname`
(ex.: `nixos-system-samsung`), e `system.configurationRevision` registra o
commit do build quando o rebuild parte de um checkout git (o app
`deploy-<host>` usa uma cópia da fonte no store e hoje perde essa marca —
para rastreabilidade, prefira `sudo nixos-rebuild switch --flake .#<host>` a
partir da raiz do repo).

## Hosts: nomeados por máquina

Há exatamente um host por máquina: `samsung`, `acer`, `vm`. O hardware vive
**dentro do host nomeado** e nunca é copiado entre hosts — cada máquina tem
os seus UUIDs, que validam com `lsblk -f` nela mesma. Em ambientes de
desktop, GNOME/Plasma/Hyprland/Sway/Niri são *opções* (`hamra.desktop.default`),
não hosts.

## Camadas

| Camada | Conteúdo |
|---|---|
| NixOS (`modules/nixos/`) | Toggles de programas: pacote, daemon, firewall, grupo, permissão de hardware |
| Home (`modules/home/`) | Config declarativa de usuário (zsh, terminal, editor, desktops HM) |
| `hosts/common` | Perfil compartilhado em `mkDefault`; deltas por host sobrescrevem |

Papel de host (NAS, VNC server) é desligado no common e ligado como delta no
host que o desempenha (ex.: `samsung` é o NAS).

## Apps fora do Nix

`hamra.mise.*` (tools, env, settings) geram o `~/.config/mise/config.toml`
via HM; o serviço `hamra-mise-install` instala as tools declaradas na
ativação (oneshot, `after home-manager-<user>.service`, re-executa quando as
tools mudam). Flatpaks e webapps seguem o mesmo padrão de módulo.

## Secrets

sops-nix + age: `secrets/*.yaml` criptografados; chaves públicas por máquina
no `.sops.yaml`; cada host decripta com a chave derivada do seu
`ssh_host_ed25519_key`. Nada em claro entra no repo nem no store.

## CI / Git Flow

CI a cada push/PR: formatação (alejandra), lint (statix + deadnix),
avaliação (`nix flake check`) e build dos toplevels de todos os hosts
(descobertos dinamicamente). Todo merge em `main` dispara o `release.yml`,
que cria a tag semver de minor seguinte com notas geradas dos commits
convencionais. Fluxo: `feature/* -> PR -> main`.

## Atualização

O nixpkgs vem pinado pelo `flake.lock` (`github:NixOS/nixpkgs/nixos-26.05`).
Atualizar = `nix flake update <input>` + rebuild. Não há auto-update: mudança
de input passa por PR como qualquer outra.

## Diretórios

| Pasta | Papel |
|---|---|
| `flake/` | hosts, apps (deploy/build), devshell |
| `hosts/<maquina>/` | identidade + hardware da máquina |
| `hosts/common/` | perfil compartilhado |
| `modules/` | toda a biblioteca (lib, nixos, home) |
| `scripts/` | assistentes (ex.: setup-nas) |
| `secrets/` | segredos criptografados |
| `docs/` | guias (NAS para iniciantes, firewall) |
