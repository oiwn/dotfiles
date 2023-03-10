-- oiwn's NeoVim config
-- updated to lua
-- resources to read:
-- https://rsdlt.github.io/posts/rust-nvim-ide-guide-walkthrough-development-debug/

-- nvim settings
-- vim.opt.clipboard = "unnamed"
vim.opt.clipboard = "unnamedplus"
vim.opt.number = true
vim.opt.rnu = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.smartindent = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.config/nvim/undodir")
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
vim.keymap.set("n", ";", ":") -- one less hit to get to command line
vim.keymap.set("n", ",<space>", ":nohlsearch<CR>") -- remove search highlights
vim.keymap.set("n", "<leader>vs", ":vsplit<CR>") -- vertical split of current window
vim.keymap.set("n", "<leader>d", ":b#<bar>bd#<cr>") -- delete buffer, keep vertical split

local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
		vim.cmd([[packadd packer.nvim]])
		return true
	end
	return false
end

local packer_bootstrap = ensure_packer()

return require("packer").startup(function(use)
	-- utils
	use("wbthomason/packer.nvim")
	use("gpanders/editorconfig.nvim")
	use("wakatime/vim-wakatime")
	use("nvim-tree/nvim-web-devicons")

	-- look and feel
	use("navarasu/onedark.nvim")
	use("Mofiqul/dracula.nvim")
	use("folke/tokyonight.nvim")
	use("EdenEast/nightfox.nvim")
	use("rebelot/kanagawa.nvim")

	use({
		"nvim-lualine/lualine.nvim",
		requires = { "kyazdani42/nvim-web-devicons" },
	})

	-- editing
	use("lukas-reineke/indent-blankline.nvim")

	-- lints and checks
	use("jose-elias-alvarez/null-ls.nvim")
	use({
		"folke/trouble.nvim",
		requires = "kyazdani42/nvim-web-devicons",
		config = function()
			require("trouble").setup({
				-- configuration
			})
		end,
	})

	-- treesetter
	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
	})

	-- search
	use({
		"nvim-telescope/telescope.nvim",
		tag = "0.1.0",
		requires = { { "nvim-lua/plenary.nvim" } },
	})

	-- lspconfig
	use("neovim/nvim-lspconfig")

	-- comments
	use({
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()
		end,
	})

	-- languages
	use("simrat39/rust-tools.nvim")

	-- completion
	use("hrsh7th/cmp-nvim-lsp")
	use("hrsh7th/cmp-buffer")
	use("hrsh7th/cmp-path")
	use("hrsh7th/cmp-cmdline")
	use("hrsh7th/nvim-cmp")

	use("hrsh7th/vim-vsnip")
	use("hrsh7th/vim-vsnip-integ")

	-- Automatically set up your configuration after cloning packer.nvim
	if packer_bootstrap then
		require("packer").sync()
	end

	-- Setup plugins
	--
	-- https://github.com/navarasu/onedark.nvim
	-- require("onedark").setup({
	-- 	style = "dark",
	-- })
	-- require("onedark").setup()
	-- require("dracula").load()
	vim.cmd([[colorscheme tokyonight]])

	-- lualine
	require("lualine").setup({
		options = { theme = "tokyonight" },
		-- options = { theme = "dracula" },
	})

	require("indent_blankline").setup({
		show_current_context = true,
		show_current_context_start = true,
		filetype = { "lua", "python", "rust" },
	})

	-- treesetter
	require("nvim-treesitter.configs").setup({
		ensure_installed = { "python", "lua", "rust", "yaml", "json", "html", "make" },
		sync_install = false,
		auto_install = true,
		ignore_install = {},
		highlight = {
			enable = true,
			disable = {},
			additional_vim_regex_highlighting = false,
		},
	})

	-- lspconfig
	require("lspconfig")["pylsp"].setup({
		settings = {
			pylsp = {
				plugins = {
					pycodestyle = {
						enabled = false,
						ignore = { "E501" },
					},
				},
			},
		},
	})
	require("lspconfig")["rust_analyzer"].setup({
		-- on_attach = on_attach,
		-- flags = lsp_flags,
		settings = {
			["rust-analyzer"] = {
				checkOnSave = {
					command = "clippy",
				},
				diagnostics = { disabled = { "inactive-code" } },
			},
		},
	})

	-- search
	require("telescope").setup({
		defaults = {
			layout_config = {
				horizontal = { width = 0.8, preview_width = 0.6 },
			},
		},
	})

	local builtin = require("telescope.builtin")
	vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
	vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
	vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
	vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
	vim.keymap.set("n", "<leader>ft", builtin.tags, {})
	vim.keymap.set("n", "<leader>fc", builtin.current_buffer_tags, {})

	-- lints
	local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
	require("null-ls").setup({
		on_attach = function(client, bufnr)
			if client.supports_method("textDocument/formatting") then
				vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
				vim.api.nvim_create_autocmd("BufWritePre", {
					group = augroup,
					buffer = bufnr,
					callback = function()
						vim.lsp.buf.format({ bufnr = bufnr })
					end,
				})
			end
		end,

		sources = {
			-- formatters [lua, python, rust]
			require("null-ls").builtins.formatting.stylua,
			require("null-ls").builtins.formatting.black,
			require("null-ls").builtins.formatting.ruff,
			-- require("null-ls").builtins.formatting.isort,
			require("null-ls").builtins.diagnostics.ruff,
			require("null-ls").builtins.formatting.rustfmt,
			-- diagnostics [python]
			require("null-ls").builtins.diagnostics.mypy,
			require("null-ls").builtins.diagnostics.pylint,
			-- completions
			require("null-ls").builtins.completion.tags,
		},
	})
	-- trouble
	require("trouble").setup({
		icons = "true",
		mode = "document_diagnostics",
	})
	vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", { silent = true, noremap = true })

	-- rust-tools
	local rt = require("rust-tools")
	rt.setup({
		server = {
			settings = {
				-- hotfix for bug in recent rust-analyzer
				-- https://github.com/simrat39/rust-tools.nvim/issues/300
				["rust-analyzer"] = {
					inlayHints = { locationLinks = false },
				},
			},
			on_attach = function(_, bufnr)
				-- Hover actions
				vim.keymap.set("n", "<C-o>", rt.hover_actions.hover_actions, { buffer = bufnr })
				-- Code action groups
				vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
			end,
		},
	})

	local cmp = require("cmp")
	cmp.setup({
		-- Enable LSP snippets
		snippet = {
			expand = function(args)
				vim.fn["vsnip#anonymous"](args.body)
			end,
		},
		mapping = {
			["<C-p>"] = cmp.mapping.select_prev_item(),
			["<C-n>"] = cmp.mapping.select_next_item(),
			-- Add tab support
			["<S-Tab>"] = cmp.mapping.select_prev_item(),
			["<Tab>"] = cmp.mapping.select_next_item(),
			["<C-S-f>"] = cmp.mapping.scroll_docs(-4),
			["<C-f>"] = cmp.mapping.scroll_docs(4),
			["<C-Space>"] = cmp.mapping.complete(),
			["<C-e>"] = cmp.mapping.close(),
			["<CR>"] = cmp.mapping.confirm({
				behavior = cmp.ConfirmBehavior.Insert,
				select = true,
			}),
		},
		-- Installed sources:
		sources = {
			{ name = "path" }, -- file paths
			{ name = "nvim_lsp", keyword_length = 3 }, -- from language server
			{ name = "nvim_lsp_signature_help" }, -- display function signatures with current parameter emphasized
			{ name = "nvim_lua", keyword_length = 2 }, -- complete neovim's Lua runtime API such vim.lsp.*
			{ name = "buffer", keyword_length = 2 }, -- source current buffer
			{ name = "vsnip", keyword_length = 2 }, -- nvim-cmp source for vim-vsnip
			{ name = "calc" }, -- source for math calculation
		},
		window = {
			completion = cmp.config.window.bordered(),
			documentation = cmp.config.window.bordered(),
		},
		formatting = {
			fields = { "menu", "abbr", "kind" },
			format = function(entry, item)
				local menu_icon = {
					nvim_lsp = "λ",
					vsnip = "⋗",
					buffer = "Ω",
					path = "🖫",
				}
				item.menu = menu_icon[entry.source.name]
				return item
			end,
		},
	})
end)
