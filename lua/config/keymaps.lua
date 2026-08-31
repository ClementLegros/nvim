-- General keymaps, plus the LSP maps.
--
-- The LSP maps are global, not buffer-local on LspAttach. Neovim's own defaults
-- (grn/gra/grr/gri/grt/gO) work the same way, deliberately: "mapped
-- unconditionally to avoid different behavior depending on whether an LSP client
-- is attached". A buffer with no server reports "not supported by any server
-- activated for this buffer" instead of silently doing something else.
local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Buffers
map("n", "<S-l>", ":bnext<CR>", opts)
map("n", "<S-h>", ":bprevious<CR>", opts)
map("n", "<leader>x", ":bdelete<CR>", opts)

-- Splits
map("n", "<leader>vs", ":vsplit<CR>", opts)
map("n", "<leader>sp", ":split<CR>", opts)

-- Diagnostics (vim.diagnostic.jump replaces the deprecated goto_prev/goto_next)
map("n", "[d", function()
    vim.diagnostic.jump({ count = -1, float = true })
end, opts)
map("n", "]d", function()
    vim.diagnostic.jump({ count = 1, float = true })
end, opts)
map("n", "<leader>d", vim.diagnostic.open_float, opts)

-- LSP
map("n", "gD", vim.lsp.buf.declaration, opts)
map("n", "gd", vim.lsp.buf.definition, opts)
map("n", "K", vim.lsp.buf.hover, opts)
map("n", "gi", vim.lsp.buf.implementation, opts)
map("n", "<C-k>", vim.lsp.buf.signature_help, opts)
map("n", "<leader>rn", vim.lsp.buf.rename, opts)
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
map("n", "gr", vim.lsp.buf.references, opts)

map("n", "gv", function()
    vim.cmd("vsplit")
    vim.lsp.buf.definition()
end, opts)
map("n", "gt", function()
    require("telescope.builtin").lsp_references()
end, opts)

map("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
end, opts)
