-- Leader must be set before plugins/keymaps are loaded.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- True color — required for catppuccin's transparent background / term colors.
opt.termguicolors = true

-- lualine's section_a already renders the mode, so nvim's own "-- INSERT --"
-- on the command line is a duplicate. See plugins/ui.lua.
opt.showmode = false
