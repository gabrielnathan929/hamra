# Contribuindo

O Hamra é uma biblioteca pessoal de configuração NixOS + Home Manager, aberta
para quem quiser estudar, copiar ou adaptar. Pull requests são bem-vindos,
desde que respeitem as regras do projeto.

## Antes de mexer

Leia o [`AGENTS.md`](AGENTS.md) — ele define as regras estruturais (camadas
NixOS vs Home, categorias por forma do app, toggle module, papel de host).
O [`ARCHITECTURE.md`](ARCHITECTURE.md) explica de onde vem a configuração que
inicializa cada máquina.

## Fluxo (Git Flow)

1. Crie a branch a partir de `main`: `feature/<nome>` (correção urgente em
   produção: `hotfix/<nome>`).
2. Commits convencionais: `feat`, `fix`, `refactor`, `chore`, `docs` — as
   notas de release são geradas agrupando por esse prefixo.
3. Abra o PR com `main` como base e preencha o template (objetivo, causa,
   riscos, testes).
4. O CI precisa estar verde: formatação (alejandra), lint (`statix` +
   `deadnix`), avaliação (`nix flake check`) e build de todos os hosts.
5. Todo merge em `main` dispara o release automático: o `release.yml` cria a
   tag semver de minor seguinte. Agrupe mudanças correlatas no mesmo PR para
   não queimar versão com ruído. Majors são manuais (quebra de contrato:
   remoção de host, opção renomeada/removida).

## Regras de ouro (resumo do AGENTS.md)

- Um arquivo por programa; o caminho da opção replica o caminho do arquivo
  (`optionals/tui/yazi.nix` -> `hamra.programs.optionals.tui.yazi`).
- Instalação de pacote sempre na camada NixOS; a camada Home é só config.
- Sem comentários no código — nomes e `description` do `mkOption` documentam.
- Hosts são nomeados por máquina (`samsung`, `acer`, `vm`); o hardware de cada
  host é gerado na própria máquina e **nunca** copiado entre hosts.
- Papel de host (NAS, VNC server) != preferência pessoal: fica `false` no
  `hosts/common` e liga como delta no host que desempenha o papel.
- Segredos: nunca em texto claro e nunca no Nix Store — `secrets/*.yaml` via
  sops-nix (instruções no AGENTS.md).

## Validar localmente antes do PR

```bash
nix develop
alejandra --check .
statix check .
deadnix .
nix flake check
```

Para mudanças estruturais, prefira `nix run .#build-<host>` (build sem
aplicar) antes do switch, e `nixos-rebuild test` antes de `switch`.
