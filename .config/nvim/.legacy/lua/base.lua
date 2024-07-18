-- ========================================================================== --
-- ==                           EDITOR SETTINGS                            == --
-- ========================================================================== --

-- alias definitions the editor settings
local set = vim.opt

-- basic settings
set.number = true				-- enable line numbers
set.relativenumber = true		-- enable relative line numbers
set.tabstop = 4					-- number of spaces a tab represents
set.shiftwidth = 4				-- number of spaces for each indentation
set.smartindent = true			-- automatically indent new lines
set.smarttab = true				-- 'shiftwidth' positions at line begin, 'tabstop' everywhere else
set.cursorline = true			-- highlight the current line
set.termguicolors = true		-- enable 24-bit rgb colors
set.mouse = 'a'					-- enable mouse usage everywhere -- TODO check if works
set.showmode = false			-- disable '-- INSERT/VISUAL/... --' in bottom line
set.updatetime = 500			-- set the 'write to disk after inactivity' time to 500ms
set.timeoutlen = 750			-- set the wait time for mapped sequence completion to 750ms
set.encoding = 'utf-8'			-- set the editor encoding to utf-8 -- TODO check if works

-- filetype plugins
vim.cmd('filetype plugin indent on')

-- leader key
vim.g.mapleader = ','			-- , as the leader key

-- basic clipboard interaction
vim.keymap.set({'n', 'x', 'o'}, 'gy', '"+y', {desc = 'Copy to clipboard'})
vim.keymap.set({'n', 'x', 'o'}, 'gp', '"+p', {desc = 'Paste clipboard content'})

