-- ========================================================================== --
-- ==                               PLUGINS                                == --
-- ========================================================================== --

-- alias definitions for the plugins
-- local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
local lazy = {}

-- install lazy.nvim (plugin manager)
function lazy.install(path)
	if not (vim.uv or vim.loop).fs_stat(path) then
		vim.fn.system({
			'git',
			'clone',
			'-- filter=blob:none',
			'https://github.com/folke/lazy.nvim.git',
			'--branch=stable',		-- latest stable release
			path,
		})
	end
end

-- lazy.nvim setup
function lazy.setup(plugins)
	if vim.g.plugins_ready then
		return
	end

	-- !TODO! comment out after lazy.nvim is installed
	--lazy.install(lazy.path)

	vim.opt.rtp:prepend(lazy.path)

	require('lazy').setup(plugins, lazy.opts)
	vim.g.plugins_ready = true
end

lazy.path = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
lazy.opts = {}

-- call setup function of lazy.nvim
lazy.setup({
--	{'nvim-tree/nvim-web-devicons'},		-- dev icons for vim (for NERDTree, lualine, ...)
	{'preservim/nerdtree',					-- nerdtree (file pane on the left)
		dependencies = { 'nvim-tree/nvim-web-devicons' }},
	-- look into nerdtree additional plugins:
	-- https://github.com/Xuyuanp/nerdtree-git-plugin
	-- https://github.com/ryanoasis/vim-devicons
	-- https://github.com/tiagofumo/vim-nerdtree-syntax-highlight
	-- https://github.com/PhilRunninger/nerdtree-buffer-ops
	-- https://github.com/PhilRunninger/nerdtree-visual-selection
	{'nvim-lualine/lualine.nvim',			-- info line at the bottom TODO: if dislike, replace with airline
		dependencies = { 'nvim-tree/nvim-web-devicons' }},
	{'nvim-treesitter/nvim-treesitter'},	-- treesitter for syntax highlighting
	{'rafi/awesome-vim-colorschemes'},		-- awesome colorschemes (including sonokai)
	{'ap/vim-css-color'},					-- enable color preview for css
	{'tpope/vim-commentary'},				-- un-, comment lines/blocks via 'gcc' or 'gcap'
	{'mg979/vim-visual-multi'},				-- multiple cursors <C-N><C-Down><C-Up> (normal mode)
	{'SirVer/ultisnips'},					-- snippet engine
	{'lervag/vimtex'},						-- latex filetype & syntax highlighting
	-- look into vimtex additional plugins
	-- https://github.com/ludovicchabant/vim-gutentags
	

	-- TODO to setup (or remove, look into):
	--{'tpope/vim-surround'},
	--{'tc50cal/vim-terminal'},
	--{'preservim/tagbar'},
	--{'neovim/nvim-lspconfig'},
	--{'hrsh7th/cmp-nvim-lsp'},
	--{'hrsh7th/cmp-buffer'},
	--{'hrsh7th/cmp-path'},
	--{'hrsh7th/cmp-cmdline'},
	--{'hrsh7th/nvim-cmp'},

	-- TODO look into:
	--{'folke/which-key.nvim'},
	--{'nvim-lua/plenary.nvim'},
	--{'nvim-telescope/telescope.nvim', branch = '0.1.x'},
	--{'nvim-telescope/telescope-fzf-native.nvim', build = 'make', enabled = is_unix},
	--{'echasnovski/mini.nvim', branch = 'stable'},
	--{'VonHeikemen/lsp-zero.nvim', branch = 'v3.x'},
})


