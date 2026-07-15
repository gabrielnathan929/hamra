# Hamra

Configuração NixOS + Home Manager organizada por toggles booleanos.

Cada programa tem seu próprio arquivo com opção e implementação. Ativa e desativa no `configuration.nix` do host, sem efeitos colaterais. Três camadas: sistema base, programas modulares e usuário (Home Manager). Tudo descoberto automaticamente.

Inclui temas visuais com wallpaper e avatar, validações em tempo de build e CI em pipeline.

```bash
nix run .#deploy-<host>    # valida e aplica
nix run .#build-<host>     # só build
```

Setup em outra máquina: `SETUP.md`.

## Projetos de terceiros

Este repositório integra e redistribui configurações de projetos externos. Todos os direitos pertencem aos seus respectivos autores.

- [Noctalia](https://github.com/noctalia-dev/noctalia) — shell/desktop Wayland (flake input `noctalia-dev/noctalia`)
- [Noctalia official-plugins](https://github.com/gabrielnathan929/official-plugins) — fork com `wallhaven` e `mpvpaper`
- [Noctalia community-plugins](https://github.com/gabrielnathan929/community-plugins) — fork com `myanimelist`
- [color_picker](https://github.com/oldirtty/color_picker) — plugin `oldirtty/color_picker`

Plugins nativos do Noctalia usados: `notes`, `timer`, `bongocat`, `translator`, `screen_recorder`.
