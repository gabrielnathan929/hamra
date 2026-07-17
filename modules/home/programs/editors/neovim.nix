{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.hamra.home.programs.editors.neovim;
  inherit (lib) mkOption mkIf types;
in {
  options.hamra.home.programs.editors.neovim = mkOption {
    type = types.bool;
    default = false;
    description = "Enable Neovim editor configuration.";
  };

  config.programs.neovim = mkIf cfg {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      telescope-nvim
      telescope-fzf-native-nvim
      nvim-treesitter
      nvim-treesitter-textobjects
      nvim-lspconfig
      which-key-nvim
      catppuccin-nvim
    ];

    extraLuaConfig = ''
      local map = vim.keymap.set

      -- better defaults
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.expandtab = true
      vim.opt.smartindent = true
      vim.opt.termguicolors = true
      vim.opt.scrolloff = 8
      vim.opt.signcolumn = "yes"
      vim.opt.mouse = "a"
      vim.opt.completeopt = "menuone,noselect"
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.splitright = true
      vim.opt.splitbelow = true

      -- telescope
      map("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
      map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
      map("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
      map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")

      -- lsp
      map("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>")
      map("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>")
      map("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>")
      map("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>")
      map("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>")
      map("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<cr>")
    '';
  };
}
