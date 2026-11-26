-- mason is used only to INSTALL language servers. The server config itself is
-- native (vim.lsp.config/enable) and lives in lua/config/lsp.lua.

require("mason").setup({
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
        },
        border = "rounded",
    },
})

-- MASON package names, which are not the lspconfig server names used in
-- config/lsp.lua (e.g. `cssls` ships in `css-lsp`). Keep this list in sync with
-- vim.lsp.enable() there.
--
-- roslyn_ls is deliberately absent: mason's registry has no roslyn package, so
-- the C# server is installed out of band as a dotnet tool. See config/lsp.lua.
local ensure_installed = {
    "lua-language-server", -- lua_ls
    "typescript-language-server", -- ts_ls
    "eslint-lsp", -- eslint
    "html-lsp", -- html
    "css-lsp", -- cssls
    "json-lsp", -- jsonls
    "tailwindcss-language-server", -- tailwindcss
    "intelephense", -- intelephense
    -- Not enabled in config/lsp.lua: started by powershell.nvim, which also
    -- uses it as debug adapter. See plugins/powershell.lua.
    "powershell-editor-services", -- powershell_es
}

-- Runs asynchronously after the registry refreshes. A wrong package name is
-- reported rather than silently ignored — that is easy to get wrong given the
-- naming mismatch above.
local registry = require("mason-registry")
registry.refresh(function()
    for _, name in ipairs(ensure_installed) do
        local ok, pkg = pcall(registry.get_package, name)
        if not ok then
            vim.schedule(function()
                vim.notify(("mason: unknown package %q"):format(name), vim.log.levels.WARN)
            end)
        elseif not pkg:is_installed() then
            pkg:install()
        end
    end
end)
