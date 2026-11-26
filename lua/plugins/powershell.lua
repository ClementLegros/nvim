-- PowerShell: powershell.nvim on top of PowerShellEditorServices (PSES).
--
-- Why a plugin and not `vim.lsp.enable("powershell_es")` like every other
-- server in config/lsp.lua: the lspconfig spec talks to PSES over stdio, which
-- gives the language server and nothing else. powershell.nvim starts PSES in a
-- terminal buffer and connects to it over a named pipe instead, so the same
-- install also provides
--   * the PowerShell Extension Terminal — a REPL sharing the server's session,
--     which is what makes "run this line / selection" possible;
--   * the debug adapter, registered with nvim-dap as `ps1`.
-- The client is still named `powershell_es` and goes through vim.lsp, so the
-- LSP keymaps of config/keymaps.lua, blink.cmp and trouble apply unchanged.
--
-- External requirements:
--   * PSES itself: installed by mason (`powershell-editor-services`, see
--     plugins/mason.lua). It bundles PSScriptAnalyzer, hence diagnostics and
--     `<leader>f` formatting with no further setup.
--   * a PowerShell to run it: `pwsh` (7+). NOT installed by mason. On Arch it
--     is `powershell-bin` from the AUR, or without root, next to the other
--     dotnet tools already used here:
--         dotnet tool install --global PowerShell
--     On Windows, Windows PowerShell 5.1 (`powershell`) is the fallback.

local shell = vim.iter({ "pwsh", "powershell" }):find(function(exe)
    return vim.fn.executable(exe) == 1
end)

if not shell then
    -- The plugin's FileType autocmd would otherwise fail on jobstart("pwsh")
    -- with a raw E475 for every .ps1 opened. Say what is missing, once.
    local warned = false
    require("powershell").initialize_or_attach = function()
        if warned then
            return
        end
        warned = true
        vim.notify(
            "PowerShell: neither `pwsh` nor `powershell` is on PATH — no LSP / debug for .ps1 files.\n"
                .. "Install it with: dotnet tool install --global PowerShell",
            vim.log.levels.WARN
        )
    end
    return
end

require("powershell").setup({
    shell = shell,
    -- The mason package root: it holds PowerShellEditorServices/ and its
    -- sibling modules (PSScriptAnalyzer, PSReadLine).
    bundle_path = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "powershell-editor-services"),
    -- The plugin calls vim.lsp.start() with its own capabilities, so the ones
    -- blink.cmp registers through vim.lsp.config("*") never reach this client.
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
        powershell = {
            codeFormatting = { preset = "OTBS" },
        },
    },
})

-- Buffer-local keys, under <leader>p (free everywhere else). Debugging uses
-- the global Visual Studio keys of plugins/dotnet.lua: F5 there launches the
-- current script when the buffer is a ps1 one.
local function ps_keys(buf)
    local function map(mode, lhs, rhs, desc, opts)
        opts = vim.tbl_extend("force", { buffer = buf, desc = "PowerShell: " .. desc }, opts or {})
        vim.keymap.set(mode, lhs, rhs, opts)
    end
    local ps = require("powershell")

    map("n", "<leader>pt", ps.toggle_term, "toggle terminal")
    -- Where a debugged script reads and writes: PSES runs it in its own
    -- console, not in dap-ui's console panel.
    map("n", "<leader>pd", ps.toggle_debug_term, "toggle debug terminal")
    -- An operator, like `d` or `c`: <leader>pe + motion, or on a selection.
    map({ "n", "x" }, "<leader>pe", ps.eval_operator, "run motion / selection in terminal", { expr = true })
    map("n", "<leader>pee", function()
        return ps.eval_operator() .. "_"
    end, "run line in terminal", { expr = true })
end

local group = vim.api.nvim_create_augroup("config-powershell", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "ps1",
    callback = function(ev)
        ps_keys(ev.buf)
    end,
})
-- Same keys inside the two terminals, so the toggles also close them.
vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = { "powershell.nvim-term", "powershell.nvim-debug_term" },
    callback = function(ev)
        ps_keys(ev.data.buf)
    end,
})
