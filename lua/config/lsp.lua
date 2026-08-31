-- Native LSP configuration (Neovim 0.11+): vim.lsp.config + vim.lsp.enable.
--
-- Servers are INSTALLED by mason (see lua/plugins/mason.lua) and their default
-- specs (cmd / filetypes / root_markers / init_options) come from nvim-lspconfig,
-- which is on the runtimepath purely as data — it is never require()'d. Only the
-- deviations from those defaults live here.

-- Diagnostics: virtual text is handled by tiny-inline-diagnostic, so disable
-- the built-in virtual_text here.
vim.diagnostic.config({
    virtual_text = false,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.HINT] = "",
            [vim.diagnostic.severity.INFO] = "",
        },
    },
    float = { border = "rounded", source = true },
})

-- roslyn_ls: the C# server Microsoft ships for VS Code. It replaced csharp-ls
-- here purely on latency — measured on ApiConverter (5 projects, .slnx), first
-- documentSymbol came back at ~19s with csharp-ls against ~4s with roslyn_ls,
-- because csharp-ls does a cold MSBuild solution load on every attach.
--
-- Nothing is overridden below: the lspconfig spec already roots at the nearest
-- .sln/.slnx (falling back to .csproj) and opens it via the `solution/open`
-- notification, so cross-project go-to-definition works without the root_dir
-- predicate csharp-ls needed here.
--
-- The binary is NOT installed by mason — its registry carries no roslyn package.
-- It comes from the dotnet tool feed and lands in ~/.dotnet/tools (which
-- .bash_profile puts on PATH):
--     dotnet tool install --global roslyn-language-server --prerelease

-- lua_ls: teach it the Neovim runtime so editing this config resolves `vim`.
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
                -- Only the Neovim Lua runtime + the luv stubs. Passing
                -- nvim_get_runtime_file("", true) here handed lua_ls every
                -- directory on the runtimepath — every plugin, ~190 MB — to
                -- index on each startup, which pushed the first response out
                -- to ~17s. Scoped like this it answers in ~4.5s.
                library = { vim.env.VIMRUNTIME .. "/lua", "${3rd}/luv/library" },
                checkThirdParty = false,
            },
            telemetry = { enable = false },
        },
    },
})

-- Every server enabled here must also be installed, by mason
-- (lua/plugins/mason.lua) — except roslyn_ls, see the note above.
vim.lsp.enable({
    "roslyn_ls", -- C#
    "lua_ls", -- Lua
    "ts_ls", -- JavaScript / TypeScript
    "eslint", -- linting for the above
    "html",
    "cssls",
    "jsonls",
    "tailwindcss",
    "intelephense", -- PHP
})

-- LSP keymaps are mapped unconditionally in config/keymaps.lua, matching what
-- Neovim does for its own grn/gra/grr defaults: a buffer with no server then
-- reports a clear "not supported" message instead of silently falling back to a
-- different behaviour (plain `gd` is a builtin word search, which is exactly how
-- a missing server can go unnoticed). Nothing here needs to wait for LspAttach:
-- completion is driven by blink.cmp, not vim.lsp.completion.
