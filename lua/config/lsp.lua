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
-- Rooting is not overridden: the lspconfig spec already roots at the nearest
-- .sln/.slnx (falling back to .csproj) and opens it via the `solution/open`
-- notification, so cross-project go-to-definition works without the root_dir
-- predicate csharp-ls needed here.
--
-- The binary is NOT installed by mason — its registry carries no roslyn package.
-- It comes from the dotnet tool feed and lands in ~/.dotnet/tools (which
-- .bash_profile puts on PATH):
--     dotnet tool install --global roslyn-language-server --prerelease
--
-- `cmd` is overridden, for two reasons:
--   * The spec launches `Microsoft.CodeAnalysis.LanguageServer` in preference
--     to the dotnet tool whenever that name is on PATH. On Windows the server
--     refused to start with "Option '--logLevel' is required" / "Option
--     '--extensionLogDirectory' is required" although the dotnet tool was
--     5.12.0 there too — pointing at another, older binary being picked up.
--     Naming the tool pins which one runs.
--   * Both options are passed anyway. 5.12.0 accepts them (checked against its
--     --help) and earlier builds require them, so this cmd starts either one.
--
-- A second addition to that spec: Roslyn resolves package references from
-- obj/project.assets.json, not from the .csproj, and when that file is missing
-- or stale it can ask the client to run the restore for it. Neovim ships two
-- copies of the lspconfig spec — the vim.pack one in site/pack/core/opt wins on
-- the runtimepath, and it is the one WITHOUT that handler, so the request would
-- be answered with MethodNotFound.
--
-- Measured on server 5.12.0: opening a project whose obj/ had been deleted did
-- NOT produce this request — the server just reported CS0103 on every framework
-- and package type and moved on, so a cold missing restore still has to be
-- fixed with `dotnet restore` by hand. The handler is insurance for the paths
-- that do send it (adding a PackageReference to a live session), not a fix for
-- that case.
--
-- A third: errors that outlive their cause until the buffer is re-opened with
-- :e. Add a file to a project — create it, rename one, `dotnet new` — and every
-- open buffer that uses its type keeps CS0246 "type not found" (measured: still
-- there 40s later). The server is NOT stale: in that same buffer,
-- go-to-definition and hover already resolve the new type.
--
-- The gap is on the client side. After reloading the project roslyn sends
-- workspace/diagnostic/refresh, and because it supports workspace diagnostics,
-- Neovim answers with a `workspace/diagnostic` pull ONLY (seen in lsp.log: three
-- identifiers — HotReloadDiagnostics, enc, WorkspaceDocumentsAndProject). The
-- per-document categories are never re-pulled, and DocumentCompilerSemantic, the
-- one carrying CS0246, is among them. Pulling each open document again clears
-- it (errors 2 -> 0, measured); :e works for the same reason.
--
-- So the refresh keeps Neovim's own behaviour and adds that per-document pull,
-- the same request the lspconfig spec makes once the solution has loaded.
local function pull_open_documents(client)
    local identifiers = vim.iter(client.dynamic_capabilities.capabilities.diagnosticProvider or {})
        :map(function(registration)
            return registration.registerOptions.identifier
        end)
        :totable()

    for bufnr in pairs(client.attached_buffers) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
            for _, identifier in ipairs(identifiers) do
                client:request("textDocument/diagnostic", {
                    identifier = identifier,
                    textDocument = vim.lsp.util.make_text_document_params(bufnr),
                }, nil, bufnr)
            end
        end
    end
end

vim.lsp.config("roslyn_ls", {
    cmd = {
        "roslyn-language-server",
        "--logLevel",
        "Information",
        "--extensionLogDirectory",
        vim.fs.joinpath(vim.fn.stdpath("log"), "roslyn"),
        "--stdio",
    },
    handlers = {
        ["workspace/_roslyn_projectNeedsRestore"] = function(_, result, ctx)
            local client = assert(vim.lsp.get_client_by_id(ctx.client_id))

            client:request("workspace/_roslyn_restore", result, function(err, response)
                if err then
                    vim.notify(err.message, vim.log.levels.ERROR, { title = "roslyn_ls" })
                end
                for _, v in ipairs(response or {}) do
                    vim.notify(v.message, vim.log.levels.INFO, { title = "roslyn_ls" })
                end
            end)

            -- vim.NIL answers the request with null; returning nothing makes the
            -- client reply with an error and the server abandons the restore.
            return vim.NIL
        end,

        ["workspace/diagnostic/refresh"] = function(err, result, ctx)
            local response = vim.lsp.handlers["workspace/diagnostic/refresh"](err, result, ctx)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            if client and not err then
                pull_open_documents(client)
            end
            return response
        end,
    },
})

-- csharp|navigation.dotnet_navigate_to_decompiled_sources is deliberately NOT
-- set: 5.12.0 returns a decompiled buffer under $TMPDIR/MetadataAsSource for a
-- type coming from a package either way. Verified by asking for the definition
-- of DbContext (Microsoft.EntityFrameworkCore) in ApiConverter with the option
-- forced to false — same MetadataAsSource URI came back.

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
