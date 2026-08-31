local map = vim.keymap.set

-- Oil: file explorer as a buffer
require("oil").setup({
    default_file_explorer = true,
    columns = {
        "icon",
        "permissions",
        "size",
        "mtime",
    },
    buf_options = {
        buflisted = false,
        bufhidden = "hide",
    },
    win_options = {
        wrap = false,
        signcolumn = "no",
        cursorcolumn = false,
        foldcolumn = "0",
        spell = false,
        list = false,
        conceallevel = 3,
        concealcursor = "nvic",
    },
    delete_to_trash = true,
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    cleanup_delay_ms = 2000,
    keymaps = {
        ["g?"] = "actions.show_help",
        ["<CR>"] = "actions.select",
        ["<C-s>"] = "actions.select_vsplit",
        ["<C-h>"] = "actions.select_split",
        ["<C-t>"] = "actions.select_tab",
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = "actions.close",
        ["<C-l>"] = "actions.refresh",
        ["-"] = "actions.parent",
        ["_"] = "actions.open_cwd",
        ["`"] = "actions.cd",
        ["~"] = "actions.tcd",
        ["gs"] = "actions.change_sort",
        ["gx"] = "actions.open_external",
        ["g."] = "actions.toggle_hidden",
        ["g\\"] = "actions.toggle_trash",
    },
    use_default_keymaps = true,
    view_options = {
        -- Show dotfiles by default (`g.` still toggles them off).
        show_hidden = true,
        is_hidden_file = function(name, _)
            return vim.startswith(name, ".")
        end,
        is_always_hidden = function(_, _)
            return false
        end,
    },
    float = {
        padding = 2,
        max_width = 0,
        max_height = 0,
        border = "rounded",
        win_options = {
            winblend = 0,
        },
    },
})
map("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- Telescope
--
-- Hidden vs ignored — two separate filters, both on by default upstream:
--   * hidden    : dotfiles (.env, .config/, .editorconfig…) — always shown here.
--   * gitignore : whatever `fd`/`rg` skip because of .gitignore. Kept ON for the
--                 default pickers (so bin/, obj/, node_modules/ stay out of the
--                 way) and lifted in the `<leader>fA` / `<leader>fG` variants —
--                 that is what surfaces a gitignored appsettings.*.json.
require("telescope").setup({
    defaults = {
        -- Default rg args + --hidden so live_grep also searches dotfiles.
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            "--glob=!**/.git/*",
        },
        -- .git/ is hidden, but never interesting.
        file_ignore_patterns = { "^%.git/", "/%.git/" },
    },
    pickers = {
        find_files = { hidden = true },
        grep_string = { additional_args = { "--hidden" } },
    },
})
map("n", "<leader><leader>", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live Grep" })
map(
    "n",
    "<leader>fA",
    "<cmd>Telescope find_files hidden=true no_ignore=true<cr>",
    { desc = "Find Files (incl. gitignored)" }
)
map("n", "<leader>fG", function()
    require("telescope.builtin").live_grep({
        additional_args = { "--no-ignore" },
    })
end, { desc = "Live Grep (incl. gitignored)" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help Tags" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent Files" })
map("n", "<leader>fc", "<cmd>Telescope commands<cr>", { desc = "Commands" })
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Keymaps" })
map("n", "<leader>fs", "<cmd>Telescope git_status<cr>", { desc = "Git Status" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Diagnostics" })

-- Window picker
require("nvim-window").setup({})
map("n", "<leader>w", function()
    require("nvim-window").pick()
end, { desc = "nvim-window: Jump to window" })

-- Lazygit (provides the :LazyGit command; needs the `lazygit` binary installed)
map("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })

-- Trouble: diagnostics, LSP results and quickfix in a navigable list
--
-- Prefix is <leader>t, not the usual <leader>x: <leader>x is already :bdelete
-- here, and adding <leader>xx under it would make every buffer delete wait out
-- `timeoutlen` first.
--
-- These are additive — `gr`, `gd`, `<leader>d` and `<leader>fd` keep their
-- current behaviour. The trouble variants are the ones worth reaching for when
-- the result set is big enough that a list beats a jump or a floating window.
require("trouble").setup({})

map("n", "<leader>tt", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Trouble: diagnostics (workspace)" })
map(
    "n",
    "<leader>tb",
    "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
    { desc = "Trouble: diagnostics (buffer)" }
)
map(
    "n",
    "<leader>ts",
    "<cmd>Trouble symbols toggle focus=false<cr>",
    { desc = "Trouble: document symbols" }
)
map("n", "<leader>tr", "<cmd>Trouble lsp_references toggle<cr>", { desc = "Trouble: references" })
map("n", "<leader>td", "<cmd>Trouble lsp_definitions toggle<cr>", { desc = "Trouble: definitions" })
map("n", "<leader>tq", "<cmd>Trouble qflist toggle<cr>", { desc = "Trouble: quickfix list" })
map("n", "<leader>tl", "<cmd>Trouble loclist toggle<cr>", { desc = "Trouble: location list" })
