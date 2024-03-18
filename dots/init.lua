-- oiwn's NeoVim config
-- updated to lua
-- resources to read:
-- https://rsdlt.github.io/posts/rust-nvim-ide-guide-walkthrough-development-debug/
-- update again to remove bullshit plugins

-- nvim settings
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.rnu = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.smartindent = false
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
  virtual_text = false
})

-- common vim keybingins
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
        ensure_installed = { "lua", "html", "json", "make", "rust", "python", "yaml", "toml" },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },
  {
    -- to select files/buffers/tags etc.
    "nvim-telescope/telescope.nvim",
    tag = "0.1.4",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      -- Keymap for telescope.nvim
      local builtin = require('telescope.builtin')
      vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
      vim.keymap.set("n", "<leader>ft", builtin.tags, {})
      vim.keymap.set("n", "<leader>fc", builtin.current_buffer_tags, {})
    end
  },
  {
    -- better status line for neovim
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "linrongbin16/lsp-progress.nvim"
    },
    config = function()
      require("lualine").setup({
        options = { theme = "auto" },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "filename" },
          lualine_c = {
            -- invoke lsp `progress` here.
            require('lsp-progress').progress,
          }
        }
      })

      -- listen lsp-progress event and refresh lualine
      vim.api.nvim_create_augroup("lualine_augroup", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        group = "lualine_augroup",
        pattern = "LspProgressStatusUpdated",
        callback = require("lualine").refresh,
      })
    end
  },
  {
    -- looks like snippets but i do not know WTF is it actually
    -- NOTE: learn how to use it or delete
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  },
  {
    -- this is rust-tools fork!
    'mrcjkb/rustaceanvim',
    version = '^4', -- Recommended
    ft = { 'rust' },
  },
  -- lspconfig
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Set up lspconfig.
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      -- setup python
      require('lspconfig').ruff_lsp.setup {
        init_options = {
          settings = {
            -- Any extra CLI arguments for `ruff` go here.
            args = {},
          }
        }
      }
      -- setup lua
      require("lspconfig").lua_ls.setup({
        capabilities = capabilities,
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
      })
    end
  },
  {
    -- used for completions
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp");
      cmp.setup({
        completion = {
          keyword_length = 3,
          debounce = 500
        },
        snippet = {
          -- REQUIRED - you must specify a snippet engine
          expand = function(args)
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
          end,
        },
        window = {
          -- completion = cmp.config.window.bordered(),
          -- documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          -- { name = 'buffer' },
        })
      })
    end
  },
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-buffer",
  {
    -- awesome plugin to display errors and warnings
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {}
  },
  {
    "numToStr/Comment.nvim",
    opts = {},
    lazy = false,
  },
  {
    -- to visualize indents
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {}
  },
  {
    -- cool plugin to see what's going on with LSP server
    "linrongbin16/lsp-progress.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lsp-progress").setup()
    end
  },
  "gpanders/editorconfig.nvim",
  -- wakatime
  "wakatime/vim-wakatime",
}

require("lazy").setup(plugins)

-- Trouble
vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", {
  silent = true, noremap = true
})
vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", {
  silent = true, noremap = true
})

-------------------------------
-- Autoformat certain documents
-------------------------------
function FormatDocument()
  vim.lsp.buf.format({ async = false })
end

vim.api.nvim_set_keymap('n', '<leader>f', '<cmd>lua FormatDocument()<CR>', {
  noremap = true, silent = true
})

-- Setup autoformats for certain document types
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.lua", "*.py", "*.rs" },
  callback = function() FormatDocument() end,
})
-------------------------------

-- Setting up LSPConfig globals
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

------------------------------------------------------------------
-- Themes cycling by leader+c
------------------------------------------------------------------
--
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

local function is_colorscheme_available(scheme_name)
  local ok, _ = pcall(function()
    vim.cmd("colorscheme " .. scheme_name)
  end)
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
THEME_CYCLER = {
  current_scheme = 1
}
function THEME_CYCLER.cycle_colorschemes()
  THEME_CYCLER.current_scheme = THEME_CYCLER.current_scheme + 1
  if THEME_CYCLER.current_scheme > #colorschemes then
    THEME_CYCLER.current_scheme = 1
  end
  set_colorscheme(colorschemes[THEME_CYCLER.current_scheme])
end

-- Bind a key to cycle through the colorschemes
vim.api.nvim_set_keymap(
  "n", "<leader>c", ":lua THEME_CYCLER.cycle_colorschemes()<CR>", { noremap = true, silent = true })

-- Set initial colorscheme to the first one or fallback
set_colorscheme(colorschemes[1])
