-- Neovim config — native API (vim.pack) — migrated from lazy.nvim
-- Load order matters:
--   1. options (sets <leader> before anything maps it)
--   2. general keymaps
--   3. plugins  (vim.pack.add + each plugin's setup)
--   4. native LSP (needs mason from the plugins step to be on runtimepath)
--   5. dotnet-menu, then easy-dotnet + nvim-dap (both define :Dotnet, see below)
--   6. powershell.nvim

require("config.options")
require("config.keymaps")
require("plugins")
require("config.lsp")

-- dotnet-menu.nvim (github.com/ClementLegros/dotnet-menu.nvim). At startup,
-- not lazily: its rename waits for a roslyn_ls signal that only a plugin
-- already set up can see. Also re-pulls roslyn diagnostics on refresh, which
-- used to live in config/lsp.lua.
require("dotnet-menu").setup()

-- easy-dotnet + nvim-dap. AFTER dotnet-menu: both define :Dotnet and the last
-- setup wins — easy-dotnet must own it (see plugins/dotnet.lua).
require("plugins.dotnet")

-- PowerShell LSP / terminal / debugging. Its debug adapter is driven by the
-- F-keys mapped in plugins/dotnet.lua.
require("plugins.powershell")
