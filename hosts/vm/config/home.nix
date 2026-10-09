{config, ...}: {
  home-manager.users.${config.hamra.users.userName}.hamra.home.programs = {
    editors = {
      neovim = true;
    };
    shell = {
      aliases = true;
      starship = true;
      zsh = true;
    };
    terminals = {
      alacritty = false;
      foot = true;
      kitty = false;
    };
    tui = {
      herdr = true;
      tmux = true;
    };
    utils = {
      fastfetch = true;
    };
  };
}
