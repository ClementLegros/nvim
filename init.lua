-- Neovim config — native API (vim.pack) — migrated from lazy.nvim
-- Load order matters:
--   1. options (sets <leader> before anything maps it)
--   2. general keymaps
--   3. plugins  (vim.pack.add + each plugin's setup)
--   4. native LSP (needs mason from the plugins step to be on runtimepath)

require("config.options")
require("config.keymaps")
require("plugins")
require("config.lsp")
