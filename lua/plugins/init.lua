-- Plugin management via Neovim's native package manager: vim.pack.
--
-- vim.pack.add() clones (if needed) and loads plugins synchronously, so each
-- plugin can be require()'d and configured immediately after. There is no
-- lazy-loading like lazy.nvim — for this config the startup cost is negligible.
--
-- Manage plugins with:
--   :lua vim.pack.update()   -- fetch + review updates in a diff buffer
--   :lua vim.pack.del({...}) -- remove a plugin from disk
-- The resolved revisions are stored in nvim-pack-lock.json.

local gh = function(repo)
    return "https://github.com/" .. repo
end

vim.pack.add({
    -- Colorscheme (added first so the theme applies as early as possible)
    { src = gh("catppuccin/nvim"), name = "catppuccin" },

    -- Shared dependencies
    { src = gh("nvim-tree/nvim-web-devicons") },
    { src = gh("nvim-lua/plenary.nvim") },

    -- UI
    { src = gh("rachartier/tiny-inline-diagnostic.nvim") },
    { src = gh("akinsho/bufferline.nvim") },
    { src = gh("nvim-lualine/lualine.nvim") },
    { src = gh("b0o/incline.nvim") },

    -- Editor / navigation
    { src = gh("stevearc/oil.nvim") },
    { src = gh("nvim-telescope/telescope.nvim") },
    { src = gh("yorickpeterse/nvim-window") },
    { src = gh("kdheepak/lazygit.nvim") },
    { src = gh("folke/trouble.nvim") },

    -- .NET menu, and C# rename / move through roslyn_ls, also driven from oil.
    -- Its own repo so it can be shared; set up in init.lua.
    { src = gh("ClementLegros/dotnet-menu.nvim") },

    -- LSP server installer (config itself is native, see config/lsp.lua)
    { src = gh("mason-org/mason.nvim") },

    -- nvim-lspconfig is used as DATA ONLY: it is never require()'d. Since v2 it
    -- ships lsp/<server>.lua specs at its repo root, which Neovim auto-discovers
    -- on the runtimepath, so vim.lsp.enable() finds them. Overrides live in
    -- config/lsp.lua.
    { src = gh("neovim/nvim-lspconfig") },

    -- Completion (pin to 1.x so vim.pack checks out a release tag, which lets
    -- blink.cmp download its prebuilt fuzzy-matcher binary — no cargo needed)
    { src = gh("saghen/blink.cmp"), version = vim.version.range("1") },
    { src = gh("rafamadriz/friendly-snippets") },
})

-- Per-plugin setup (order: colorscheme first, then the rest)
require("plugins.colorscheme")
require("plugins.ui")
require("plugins.editor")
require("plugins.mason")
require("plugins.completion")
