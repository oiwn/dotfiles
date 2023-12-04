-- oiwn's NeoVim config
-- updated to lua
-- resources to read:
-- https://rsdlt.github.io/posts/rust-nvim-ide-guide-walkthrough-development-debug/

-- nvim settings
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.rnu = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.smartindent = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.config/nvim/undodir")
vim.opt.swapfile = false
vim.o.termguicolors = true
vim.g.mapleader = ","

vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
vim.opt.shortmess = vim.opt.shortmess + { c = true }
vim.api.nvim_set_option("updatetime", 300)

-- set to false if using lsp_lines
-- or just do not want to see bloating long lines of text
vim.diagnostic.config({
  virtual_text = true,
})

-- keybingins
vim.keymap.set("n", ";", ":")                       -- one less hit to get to command line
vim.keymap.set("n", ",<space>", ":nohlsearch<CR>")  -- remove search highlights
vim.keymap.set("n", "<leader>vs", ":vsplit<CR>")    -- vertical split of current window
vim.keymap.set("n", "<leader>d", ":b#<bar>bd#<cr>") -- delete buffer, keep vertical split

-- setup lazy package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
  -- themes
  "rebelot/kanagawa.nvim",
  "navarasu/onedark.nvim",
  "Mofiqul/dracula.nvim",
  "folke/tokyonight.nvim",
  "EdenEast/nightfox.nvim",
  -- tree-sitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.configs")

      configs.setup({
        ensure_installed = { "lua", "html", "json", "make", "rust", "python" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  -- telescope
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.4",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  -- lualine
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = { theme = "dracula" }
      })
    end
  },
  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("lspconfig").lua_ls.setup {
        settings = {
          Lua = {
            runtime = {
              -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
              version = 'LuaJIT',
            },
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = { 'vim' },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              library = vim.api.nvim_get_runtime_file("", true),
            },
            -- Do not send telemetry data containing a randomized but unique identifier
            telemetry = {
              enable = false,
            },
            format = {
              enable = true,
              defaultConfig = {
                indent_style = "tab",
              },
            },
          },
        },
      }
    end
  },
  -- touble
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
    }
  },
  -- "simrat39/rust-tools.nvim"
  "nvimtools/none-ls.nvim"
}

require("lazy").setup(plugins)

-- Keymap for telescope.nvim
local builtin = require('telescope.builtin')
vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
vim.keymap.set("n", "<leader>ft", builtin.tags, {})
vim.keymap.set("n", "<leader>fc", builtin.current_buffer_tags, {})

-- Keymap for lspconfig


--[[ Setup language servers.
local lspconfig = require('lspconfig')
lspconfig.rust_analyzer.setup {
  -- Server-specific settings. See `:help lspconfig-setup`
  settings = {
    ['rust-analyzer'] = {
      checkOnSave = {
        command = "clippy",
      }
    },
  },
}
-- lspconfig.ruff_lsp.setup{}
]]
--

--[[
local null_ls = require("null-ls")
null_ls.setup({
    sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.ruff,
    },
})
]]
--

-- Lsp related keybindings
function FormatDocument()
  vim.lsp.buf.format({ async = false })
end

vim.api.nvim_set_keymap('n', '<leader>f', '<cmd>lua FormatDocument()<CR>', { noremap = true, silent = true })

-- Setup autoformats for certain document types
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.lua", "*.py", "*.rs" },
  callback = function() FormatDocument() end,
})

-- Themes cycling by leader+c
-- Define a list of colorschemes
local colorschemes = {
  "kanagawa",
  "onedark",
  "dracula",
  "tokyonight-moon",
  "tokyonight-night",
  "kanagawa-wave",
  "terafox",
  "nightfox"
}

-- Function to check if a colorscheme is available
local function is_colorscheme_available(scheme_name)
  local ok, _ = pcall(vim.cmd, "colorscheme " .. scheme_name)
  return ok
end

-- Set a fallback colorscheme
local fallback_colorscheme = "default"

-- Function to set a colorscheme with fallback
local function set_colorscheme(scheme_name)
  if is_colorscheme_available(scheme_name) then
    vim.cmd("colorscheme " .. scheme_name)
  else
    vim.cmd("colorscheme " .. fallback_colorscheme)
  end
end

-- Set the initial colorscheme with fallback
set_colorscheme(colorschemes[1])

-- Define a function to cycle through the colorschemes
local current_scheme = 1
function cycle_colorschemes()
  current_scheme = current_scheme + 1
  if current_scheme > #colorschemes then
    current_scheme = 1
  end
  set_colorscheme(colorschemes[current_scheme])
end

-- Bind a key to cycle through the colorschemes
vim.api.nvim_set_keymap(
  "n", "<leader>c", ":lua cycle_colorschemes()<CR>", { noremap = true, silent = true })

-- Set initial colorscheme to the first one or fallback
set_colorscheme(colorschemes[1])
