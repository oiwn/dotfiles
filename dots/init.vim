" oiwn's NeoVim config

set encoding=utf-8
scriptencoding utf-8

" filetype plugin on

set clipboard=unnamed
set number " set line numbers
set rnu " relative line numbers
set splitbelow splitright " better splits
set smartindent " smart autoindenting when starting a new line
set noswapfile
set undofile undodir=~/.config/nvim/undodir

let g:mapleader=',' " Set leader to the comma key.
" One less hit to get to the command-line.
nnoremap ; :
" turn off search highlight
nnoremap ,<space> :nohlsearch<CR>

" no more arrows motions
nnoremap <silent> <up>    <nop>
nnoremap <silent> <down>  <nop>
nnoremap <silent> <left>  <nop>
nnoremap <silent> <right> <nop>

" fance Esc
inoremap jk <esc>

" Enable true colors
if has('nvim') || has('termguicolors')
  set termguicolors
endif

" activate true color support
" TODO: do i even need it now?
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" ignore junk
set wildignore+=*.swp,*.pyc,*.bak,*.class,*.orig
set wildignore+=.git,.hg,.bzr,.svn
set wildignore+=*.jpg,*.bmp,*.gif,*.png,*.jpeg,*.svg
set wildignore+=build/*,tmp/*,vendor/cache/*,bin/*
set wildignore+=.sass-cache/*,*node_modules/*,*/target/*
set wildignore+=__pycache__/*,.cache/

call g:plug#begin('~/.config/nvim/plugins')
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'

" Snippet completion source for nvim-cmp
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'

" Other usefull completion sources
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-buffer'

" Lint and code analysis
Plug 'w0rp/ale'

" Look and feel
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'nvim-lualine/lualine.nvim'
Plug 'kyazdani42/nvim-web-devicons'

" treesetter support themes
Plug 'Mofiqul/dracula.nvim'
Plug 'rktjmp/lush.nvim'
Plug 'ellisonleao/gruvbox.nvim'
Plug 'shaunsingh/nord.nvim'
Plug 'tomasiser/vim-code-dark'
Plug 'marko-cerovac/material.nvim'
Plug 'bluz71/vim-nightfly-guicolors'
Plug 'bluz71/vim-moonfly-colors'
Plug 'mhartington/oceanic-next'
Plug 'Th3Whit3Wolf/space-nvim'
Plug 'tanvirtin/monokai.nvim'
Plug 'navarasu/onedark.nvim'
Plug 'shaunsingh/moonlight.nvim'
Plug 'rose-pine/neovim'
Plug 'sainnhe/sonokai'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'rafamadriz/neon'
Plug 'catppuccin/nvim'
Plug 'projekt0n/github-nvim-theme'
Plug 'glepnir/zephyr-nvim'
Plug 'challenger-deep-theme/vim', { 'as': 'challenger-deep' }

" Utils
Plug 'editorconfig/editorconfig-vim'
Plug 'wakatime/vim-wakatime'
Plug 'xolox/vim-misc'
Plug 'xolox/vim-colorscheme-switcher'
Plug 'scrooloose/nerdcommenter'
" FZF Search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" Rust
Plug 'rust-lang/rust.vim'
" To enable more of the features of rust-analyzer, such as inlay hints and more!
Plug 'simrat39/rust-tools.nvim'
" Markdown
Plug 'plasticboy/vim-markdown'

call g:plug#end()

" [Tags] Command to generate tags file
let g:fzf_tags_command = 'ctags -R'
" Ignore hidden files for ag search
let $FZF_DEFAULT_COMMAND = 'rg --hidden --ignore .git -g ""'

" nerd*
let g:NERDCreateDefaultMappings = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDCompactSexyComs = 1
let g:NERDSpaceDelims = 1
let g:NERDRemoveExtraSpaces = 1

" vim-markdown
let g:vim_markdown_folding_disabled = 1

" Linters and checkers

" ALE
let g:ale_sign_error = '●' " Less aggressive than the default '>>'
let g:ale_sign_warning = '.'
let g:ale_lint_on_enter = 0 " Less distracting when opening a new file
let g:ale_lint_on_text_changed = 'never'

" linters for python: flake8, pyre
" \ 'rust': ['analyzer']

let g:ale_linters = {
\ 'python': ['mypy', 'pylint'],
\}
" 'rust': ['rustfmt']
let g:ale_fixers = {
\ 'python': ['black'],
\ 'rust': ['rustfmt']
\}
let g:ale_fix_on_save = 1

" FZF search
set rtp+=/usr/local/opt/fzf

" Colorscheme
set background=dark
" options:
" onedark dracula monokain nord
colorscheme onedark

" completion setting
" Set completeopt to have a better completion experience
" :help completeopt
" menuone: popup even when there's only one match
" noinsert: Do not insert text until a selection is made
" noselect: Do not select, force user to select one from the menu
set completeopt=menuone,noinsert,noselect
" Avoid showing extra messages when using completion
set shortmess+=c


" Useful commands
com! FormatJSON %!python -m json.tool

" keybindings
" close current buffer keep vsplit!
nnoremap <leader>d :b#<bar>bd#<cr>
" vertical split
nnoremap <leader>vs :vsplit<cr>
" quit from terminal runing inside nvim
tnoremap <Esc> <C-\><C-n>
" close all buffers
nnoremap <leader>o :%bd\|e#<cr>

" fzf bindings
nnoremap <leader>ff :GFiles<cr>
nnoremap <leader>fs :Rg<cr>
nnoremap <leader>fb :Buffers<cr>
nnoremap <leader>fl :Lines<cr>
nnoremap <leader>fd :BLines<cr>
nnoremap <leader>ft :Tags<cr>
nnoremap <leader>fc :BTags<cr>

lua <<EOF
require'lualine'.setup()

require("indent_blankline").setup {
  show_current_context = true,
  show_current_context_start = true,
}

require'nvim-treesitter.configs'.setup {
  -- One of "all", "maintained" (parsers with maintainers), or a list of languages
  ensure_installed = { "python", "yaml", "json", "rust", "html" },
  -- Install languages synchronously (only applied to `ensure_installed`)
  sync_install = false,
  highlight = {
    -- `false` will disable the whole extension
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}

-- Configure LSP through rust-tools.nvim plugin.
-- rust-tools will configure and enable certain LSP features for us.
-- See https://github.com/simrat39/rust-tools.nvim#configuration
-- local nvim_lsp = require'lspconfig'
require'lspconfig'.pyright.setup{}

local rust_tools_opts = {
    tools = { -- rust-tools options
        autoSetHints = true,
        hover_with_actions = true,
        inlay_hints = {
            show_parameter_hints = false,
            parameter_hints_prefix = "",
            other_hints_prefix = "",
        },
    },

    -- all the opts to send to nvim-lspconfig
    -- these override the defaults set by rust-tools.nvim
    -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
    server = {
        -- on_attach is a callback called when the language server attachs to the buffer
        -- on_attach = on_attach,
        settings = {
            -- to enable rust-analyzer settings visit:
            -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
            ["rust-analyzer"] = {
                -- enable clippy on save
                checkOnSave = {
                    command = "clippy"
                },
            }
        }
    },
}

require('rust-tools').setup(rust_tools_opts)

-- Setup Completion
-- See https://github.com/hrsh7th/nvim-cmp#basic-configuration
local cmp = require'cmp'
cmp.setup({
  completion = {
    autocomplete = false
  },
  -- Enable LSP snippets
  snippet = {
    expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
    end,
  },
  mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    -- Add tab support
    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
    ['<Tab>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Insert,
      select = true,
    })
  },

  -- Installed sources
  sources = {
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'path' },
    { name = 'buffer' },
  },
})
EOF

