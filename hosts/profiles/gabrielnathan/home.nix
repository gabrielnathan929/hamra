# Home Manager toggles for this profile (user-level apps: editor, shell,
# terminal, tui tools). Same rule as the other profile files: a host can
# override any of them with a plain delta.
{
  config,
  lib,
  ...
}: {
  home-manager.users.${config.hamra.users.userName}.hamra.home.programs = lib.mkDefault {
    editors.neovim = true;
    shell = {
      aliases = true;
      starship = true;
      zsh = true;
    };
    terminals = {
      alacritty = true;
      foot = true;
      kitty = true;
    };
    tui = {
      herdr = true;
      tmux = true;
    };
    utils.fastfetch = true;
  };
}
