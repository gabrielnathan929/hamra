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

  config = mkIf cfg {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      withNodeJs = true;
      withPython3 = true;
      initLua = ''
        require("config.lazy")
      '';
    };

    home.packages = with pkgs; [
      lua-language-server
      nil
      ripgrep
      fd
      lazygit
      alejandra
      stylua
    ];

    xdg.configFile = {
      "nvim/lua/config/lazy.lua".text = ''
        local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
        if not vim.uv.fs_stat(lazypath) then
          vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable",
            lazypath,
          })
        end
        vim.opt.rtp:prepend(lazypath)

        require("lazy").setup({
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          { import = "plugins" },
        }, {
          defaults = {
            lazy = true,
            version = false,
          },
          install = {
            colorscheme = { "catppuccin" },
          },
          checker = {
            enabled = true,
            notify = false,
          },
          performance = {
            cache = {
              enabled = true,
            },
            rtp = {
              disabled_plugins = {
                "gzip",
                "matchit",
                "matchparen",
                "netrwPlugin",
                "tarPlugin",
                "tohtml",
                "tutor",
                "zipPlugin",
              },
            },
          },
        })
      '';

      "nvim/lua/config/options.lua".text = ''
        vim.opt.number = true
        vim.opt.relativenumber = false
        vim.opt.mouse = "a"
        vim.opt.showmode = false
        vim.opt.breakindent = true
        vim.opt.undofile = true
        vim.opt.ignorecase = true
        vim.opt.smartcase = true
        vim.opt.signcolumn = "yes"
        vim.opt.updatetime = 250
        vim.opt.timeoutlen = 300
        vim.opt.splitright = true
        vim.opt.splitbelow = true
        vim.opt.list = true
        vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
        vim.opt.inccommand = "split"
        vim.opt.cursorline = true
        vim.opt.scrolloff = 10
        vim.opt.hlsearch = true
        vim.opt.termguicolors = true
      '';

      "nvim/lua/config/keymaps.lua".text = ''
        local map = vim.keymap.set

        map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Move down visually" })
        map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Move up visually" })

        map("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to left window" })
        map("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to right window" })
        map("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to lower window" })
        map("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to upper window" })

        map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
      '';

      "nvim/lua/config/autocmds.lua".text = ''
        local augroup = vim.api.nvim_create_augroup("LazyVim", { clear = true })

        vim.api.nvim_create_autocmd("TextYankPost", {
          group = augroup,
          callback = function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 40 })
          end,
          desc = "Highlight yanked text briefly",
        })

        vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
          group = augroup,
          pattern = "*.nix",
          callback = function()
            vim.bo.shiftwidth = 2
            vim.bo.tabstop = 2
            vim.bo.softtabstop = 2
            vim.bo.expandtab = true
          end,
          desc = "Set nix file indentation",
        })
      '';
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = "nvim.desktop";
        "text/csv" = "nvim.desktop";
        "text/tab-separated-values" = "nvim.desktop";
        "text/markdown" = "nvim.desktop";
        "text/x-shellscript" = "nvim.desktop";
        "text/x-makefile" = "nvim.desktop";
        "text/x-c" = "nvim.desktop";
        "text/x-c++" = "nvim.desktop";
        "text/x-python" = "nvim.desktop";
        "text/x-ruby" = "nvim.desktop";
        "text/x-java" = "nvim.desktop";
        "text/x-nix" = "nvim.desktop";
        "text/x-lua" = "nvim.desktop";
        "text/javascript" = "nvim.desktop";
        "text/typescript" = "nvim.desktop";
        "text/css" = "nvim.desktop";
        "text/html" = "nvim.desktop";
        "text/xml" = "nvim.desktop";
        "text/yaml" = "nvim.desktop";
        "text/x-tex" = "nvim.desktop";
        "application/json" = "nvim.desktop";
      };
    };
  };
}
