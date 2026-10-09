{config, ...}: {
  home-manager.users.${config.hamra.users.userName}.hamra.home.programs = {
    editors = {
      neovim = false;
    };
    shell = {
      aliases = true;
      starship = true;
      zsh = true;
    };
    terminals = {
      alacritty = true;
      foot = true;
      kitty = false;
    };
    tui = {
      herdr = false;
      tmux = true;
    };
    utils = {
      fastfetch = false;
    };
  };
}
