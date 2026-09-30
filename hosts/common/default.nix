# Perfil comum a todos os hosts.
# Cada host importa este módulo e declara apenas os DELTAS.
#
# Regra do arquivo: só entram aqui toggles = true que vale para
# TODO host. O que está omisso usa o default do próprio módulo
# (false em optionals; default do tier em core).
#
# Categorias por forma do app:
#   core/optionals + gui/      apps de janela (navegadores, IDEs, comunicação, segurança)
#   core/optionals + tui/      interfaces em terminal (btop, lazygit, yazi, opencode...)
#   core/optionals + cli/      ferramentas de linha de comando e toolchains (git, ripgrep, gcc...)
#   core/optionals + services/ daemons e integrações (samba, docker, flatpak, xdg...)
#   optionals + media/         players e criação de mídia (mpv, kodi, obs, spotify...)
#   optionals + games/         jogos
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  hamraLib = import ../../modules/lib {inherit lib;};
in {
  hamra = lib.mkDefault {
    env = {
      editor = pkgs.neovim;
      browser = pkgs.chromium;
      terminal = pkgs.foot;
      filemanager = pkgs.nautilus;
    };

    packages.extra = [];

    mobile.android = false;

    programs = {
      core = {
        cli.git = true;
        tui.opencode = true;
      };

      optionals = {
        gui = {
          vscode = true;
          discord = true;
          remmina = true;
          keepassxc = true;
          "ente-auth" = true;
        };

        tui.clamp = true;
      };
    };
  };

  programs.nix-ld.enable = true;

  system.stateVersion = "26.05";

  home-manager = {
    extraSpecialArgs = {
      inherit inputs hamraLib;
      wallpaperPath = config.hamra.theme.wallpaper;
      themesDir = ../../modules/nixos/core/theme/themes;
      keyboard = config.hamra.keyboard;
      desktop = config.hamra.desktop.default;
      displays = config.hamra.displays;
      wayvnc = config.hamra.programs.optionals.services.wayvnc;
      env = config.hamra.env;
    };
    users.${config.hamra.users.userName} = {
      home.stateVersion = "26.05";
      imports = [../../modules/home];

      hamra.home.programs = {
        editors.neovim = true;
      };
    };
  };
}
