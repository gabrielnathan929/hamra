## Objetivo

<!-- O que este PR faz, em uma frase. -->

## Problema e causa

<!-- Qual era o comportamento errado e por quê. -->

## Solução

<!-- O que muda e onde. -->

## Arquivos afetados

<!-- Liste os arquivos/grupos de arquivos. -->

## Riscos

<!-- Hardware tocado? hosts/common? Segredos? Regressão possível? -->

## Validação

- [ ] `nix develop --command alejandra --check .`
- [ ] `nix develop --command statix check .`
- [ ] `nix develop --command deadnix .`
- [ ] `nix flake check`
- [ ] `nix run .#build-<host>` (se mudança estrutural)
- [ ] `nixos-rebuild test` antes de `switch` (se mudança de sistema)
- [ ] Toca `hosts/*/hardware-configuration.nix`? Justificar e validar na máquina alvo (`lsblk -f`)

## Impacto arquitetural

<!-- Opções mudando de nome/default? Host adicionado/removido? Doc atualizada? -->

## Intervenção humana necessária

<!-- Hardware, secrets, remotes, bootloader, auth — ou "nenhuma". -->
