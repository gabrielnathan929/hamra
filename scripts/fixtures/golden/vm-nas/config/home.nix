{config, ...}: {
  home-manager.users.${config.hamra.users.userName}.hamra.home.programs = {
    editors = {
      neovim = false;
    };
    games = {
      mangohud = false;
    };
    shell = {
      aliases = true;
      flakeDir = null;
      starship = true;
      zsh = true;
    };
    terminals = {
      alacritty = false;
      foot = true;
      kitty = false;
    };
    tui = {
      herdr = false;
      tmux = true;
    };
    utils = {
      fastfetch = true;
    };
  };
}
