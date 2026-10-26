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
      flakeDir = "\$HOME/Projetos/hamra";
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
