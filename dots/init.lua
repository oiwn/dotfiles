-- oiwn's NeoVim config
-- updated to lua

-- nvim settings
vim.opt.clipboard = "unnamed"
vim.opt.number = true
vim.opt.rnu = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.smartindent = true
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.config/nvim/undodir")
vim.o.termguicolors = true
vim.g.mapleader = ","

-- set to false if using lsp_lines
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

	-- Automatically set up your configuration after cloning packer.nvim
	if packer_bootstrap then
		require("packer").sync()
	end

	-- Setup plugins
	--
	-- https://github.com/navarasu/onedark.nvim
	require("onedark").setup({
		style = "dark",
	})
	require("onedark").load()

	-- lualine
	require("lualine").setup({
		options = { theme = "onedark" },
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
	-- require("lspconfig")["pyright"].setup({})
	require("lspconfig")["rust_analyzer"].setup({
		-- on_attach = on_attach,
		-- flags = lsp_flags,
		settings = {
			["rust-analyzer"] = {
				checkOnSave = {
					command = "clippy",
				},
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
			require("null-ls").builtins.formatting.rustfmt,
			-- diagnostics [python]
			require("null-ls").builtins.diagnostics.mypy,
			require("null-ls").builtins.diagnostics.pylint,
		},
	})
	-- trouble
	require("trouble").setup({
		icons = "true",
		mode = "document_diagnostics",
	})
	vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", { silent = true, noremap = true })
	vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", { silent = true, noremap = true })
end)
