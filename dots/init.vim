" oiwn's NeoVim config

set encoding=utf-8
scriptencoding utf-8

filetype plugin on

set clipboard=unnamed
set number " set line numbers
set rnu " relative line numbers
set splitbelow splitright " better splits
set smartindent " smart autoindenting when starting a new line

set undofile undodir=~/.config/nvim/undodir
" Set leader to the comma key.
let g:mapleader=','
" One less hit to get to the command-line.
nnoremap ; :
" turn off search highlight
nnoremap ,<space> :nohlsearch<CR>

" no more arrows motions.
nnoremap <silent> <up>    <nop>
nnoremap <silent> <down>  <nop>
nnoremap <silent> <left>  <nop>
nnoremap <silent> <right> <nop>

" activate true color support
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

" Lint and code analysis
Plug 'w0rp/ale'

" Look and feel
Plug 'dracula/vim',{ 'as': 'dracula' }
Plug 'morhetz/gruvbox'
Plug 'arcticicestudio/nord-vim'
Plug 'lifepillar/vim-solarized8'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" treesetter support themes
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
" Utils
" Plug 'xolox/vim-easytags'
Plug 'jceb/vim-orgmode'
Plug 'editorconfig/editorconfig-vim'
Plug 'wakatime/vim-wakatime'
Plug 'xolox/vim-misc'
Plug 'xolox/vim-colorscheme-switcher'
" Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'scrooloose/nerdcommenter'
Plug 'asymotion/vim-easymotion'
" FZF Search
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
" Languages
Plug 'sheerun/vim-polyglot'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
" Python
Plug 'Vimjas/vim-python-pep8-indent'
" JavaScript
Plug 'othree/yajs.vim', { 'for': 'javascript' }
Plug 'gavocanov/vim-js-indent', { 'for': 'javascript' }
Plug 'mxw/vim-jsx'
Plug 'othree/es.next.syntax.vim'
" SCSS
Plug 'cakebaker/scss-syntax.vim'
" Rust
Plug 'rust-lang/rust.vim'
" Markdown
Plug 'plasticboy/vim-markdown'

call g:plug#end()

" for Go
au FileType go set noexpandtab
au FileType go set shiftwidth=4
au FileType go set softtabstop=4
au FileType go set tabstop=4

" [Tags] Command to generate tags file
let g:fzf_tags_command = 'ctags -R'
" Ignore hidden files for ag search
let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -g ""'

" nerd*
let g:NERDCreateDefaultMappings = 1
let g:NERDDefaultAlign = 'left'
let g:NERDCommentEmptyLines = 1
let g:NERDCompactSexyComs = 1
let g:NERDSpaceDelims = 1
let g:NERDRemoveExtraSpaces = 1

" Powerline & Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#neomake#enabled = 0
let g:airline_detected_modified = 1
let g:airline_powerline_fonts = 1
let g:Powerline_symbols = 'fancy'

" Highlight
let g:python_highlight_all = 1

" vim-markdown
let g:vim_markdown_folding_disabled = 1

" Linters and checkers

" ALE
let g:ale_sign_error = '●' " Less aggressive than the default '>>'
let g:ale_sign_warning = '.'
let g:ale_lint_on_enter = 0 " Less distracting when opening a new file
let g:ale_lint_on_text_changed = 'never'

" linters for python: flake8, pyre
let g:ale_linters = {
\ 'python': ['mypy', 'pylint'],
\ 'rust': ['cargo']
\}
let g:ale_fixers = {
\ 'python': ['black'],
\ 'rust': ['rustfmt']
\}
let g:ale_fix_on_save = 1
" let g:rustfmt_autosave = 1

filetype plugin indent on
syntax enable

" FZF search
set rtp+=/usr/local/opt/fzf

" Colorscheme
set background=dark
" options:
" onedark dracula monokain nord
" solarized8 solarized8_flat
" solarized8_high solarized8_low
colorscheme onedark

" Commands
com! FormatJSON %!python -m json.tool

" keybindings
" close current buffer keep vsplit!
nnoremap <leader>d :b#<bar>bd#<cr>
nnoremap <leader>n :NERDTreeToggle<cr>
nnoremap <leader>vs :vsplit<cr>
" quit from terminal runing inside nvim
tnoremap <Esc> <C-\><C-n>
" close all buffers
nnoremap <leader>o :%bd\|e#<cr>

" fzf bindings
nnoremap <leader>ff :GFiles<cr>
nnoremap <leader>fs :Ag<cr>
nnoremap <leader>fb :Buffers<cr>
nnoremap <leader>fl :Lines<cr>
nnoremap <leader>fd :BLines<cr>
nnoremap <leader>ft :Tags<cr>
nnoremap <leader>fc :BTags<cr>

" highlights
" lua <<EOF
" require'nvim-treesitter.configs'.setup {
"   ensure_installed = { "python", "yaml", "json", "comment", "css", "html" },
"   ignore_install = { "ruby" }, -- List of parsers to ignore installing
"   highlight = {
"     enable = true,              -- false will disable the whole extension
"     disable = { "c" },          -- list of language that will be disabled
"   },
" }
" EOF
"
