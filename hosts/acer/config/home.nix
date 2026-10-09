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
      alacritty = true;
      foot = true;
      kitty = true;
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
