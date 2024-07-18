-- ========================================================================== --
-- ==                         PLUGIN CONFIGURATION                         == --
-- ========================================================================== --

-- ====================================== --
-- ==         nvim-web-devicons        == --
-- ====================================== --
-- TODO: check if working, else remove, isn't really needed:
--require('nvim-web-devicons').setup()
vim.g.webdevicons_enable_nerdtree_maps = 1
vim.g.webdevicons_nerdtree_maps = {
	Icon = '',
	OpenedFile = '',
	OpenedFolder = '',
	EmptyFolder = '',
	Symlink = ''
}

-- ====================================== --
-- ==             nerdtree             == --
-- ====================================== --
vim.keymap.set('n', '<C-t>', '<cmd>NERDTreeToggle<cr>', {desc = 'Toggle NERDTree'})
vim.keymap.set('n', '<C-f>', '<cmd>NERDTreeFocus<cr>', {desc = 'Focus NERDTree'})
vim.keymap.set('n', '<leader>f', '<cmd>NERDTreeFind<cr>', {desc = 'Find NERDTree'})

-- ====================================== --
-- ==           lualine.nvim           == --
-- ====================================== --
-- TODO: check if needed:
-- require('lualine').setup()

-- ====================================== --
-- ==          nvim-treesitter         == --
-- ====================================== --
require('nvim-treesitter.configs').setup({
	-- auto install missing parsers
	auto_install = true,

	-- list of parsers
	ensure_installed = {
		'bash',
		'bibtex',
		'c',
		'cpp',
		'css',
		'csv',
		'dockerfile',
		'gitignore',
		'html',
		'java',
		'javascript',
		'json',
		'kotlin',
		-- 'latex',
		'lua',
		'luadoc',
		'make',
		'markdown',
		'matlab',
		'python',
		'regex',
		'rust',
		'scss',
		'sql',
		'svelte',
		'swift',
		'typescript',
		'vim',
		'vimdoc',
		'vue',
		'xml',
		'yaml',
	},

	highlight = {
		enable = true,
		disable = {
			'latex',
		},
		additional_vim_regex_highlighting = {
			'latex',
			'markdown',
		},
	},
})

-- ====================================== --
-- ==     awesome-vim-colorschemes     == --
-- ====================================== --
vim.cmd.colorscheme('sonokai')				-- TODO: test 'tokyonight' colorscheme (+ lualine!)

-- ====================================== --
-- ==             ultisnips            == --
-- ====================================== --
local ultisnips_snippets = vim.fn.expand('$HOME/.config/nvim/UltiSnips')

vim.g.tex_flavor = 'latex'					-- use tex.snippets for latex (instead of tex_plain)
vim.g.UltiSnipsSnippetDirectories = { ultisnips_snippets, 'UltiSnips' }
vim.g.UltiSnipsExpandTrigger = '<c-j>'
vim.g.UltiSnipsJumpForwardTrigger = '<c-k>'
--vim.g.UltiSnipsJumpBackwardTrigger = '<c-l>'
vim.g.UltiSnipsListSnippets = '<c-l>'

-- ====================================== --
-- ==              vimtex              == --
-- ====================================== --
vim.g.vimtex_view_general_viewer = 'okular'	-- show pdf in okular
vim.g.vimtex_view_general_options = '--unique file:@pdf\\#src:@line@tex'
-- vim.g.vimtex_compiler_method = 'latexmk'	-- use latexmk as compiler method (default)


