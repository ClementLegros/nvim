vim.g.mapleader = " "

local opt = vim.opt

opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprevious<CR>", opts)
keymap("n", "<leader>x", ":bdelete<CR>", opts)

vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
vim.keymap.set("n", "gv", function()
    vim.cmd('vsplit')
    vim.lsp.buf.definition()
end)
vim.keymap.set("n", "gt", function()
    require('telescope.builtin').lsp_references()
end)

vim.keymap.set("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
end, opts)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

vim.keymap.set("n", "<leader>vs", ":vsplit<CR>")
vim.keymap.set("n", "<leader>sp", ":split<CR>")

require("lazy").setup({
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                transparent_background = true,
                term_colors = true,
                integrations = {
                    cmp = true,
                    telescope = {
                        enabled = true,
                    },
                    mason = true,
                    native_lsp = {
                        enabled = true,
                        virtual_text = {
                            errors = { "italic" },
                            hints = { "italic" },
                            warnings = { "italic" },
                            information = { "italic" },
                        },
                        underlines = {
                            errors = { "underline" },
                            hints = { "underline" },
                            warnings = { "underline" },
                            information = { "underline" },
                        },
                    },
                },
            })
            vim.cmd.colorscheme("catppuccin")
        end,
    },
    --[[{
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                hijack_netrw = true,
                disable_netrw = true,
                view = { width = 34 },
                renderer = {
                    icons = { show = { file = true, folder = true, folder_arrow = true, git = true } },
                },
                filters = { dotfiles = false },
            })

            vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer (nvim-tree)" })
            vim.keymap.set("n", "<leader>o", "<cmd>NvimTreeFindFile<cr>", { desc = "Reveal file in tree" })
        end,
    },]]--
    {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "VeryLazy",
        priority = 1000,
        config = function()
            require("tiny-inline-diagnostic").setup()
            vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
        end,
    },
    {
        "stevearc/oil.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
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
                    show_hidden = false,
                    is_hidden_file = function(name, bufnr)
                        return vim.startswith(name, ".")
                    end,
                    is_always_hidden = function(name, bufnr)
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
            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        cmd = "Telescope",
        keys = {
            { "<leader><leader>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
            { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
            { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
            { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
            { "<leader>fs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
            { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
        },
    },
    {
        "yorickpeterse/nvim-window",
        keys = {
            { "<leader>w", "<cmd>lua require('nvim-window').pick()<cr>", desc = "nvim-window: Jump to window" },
        },
        config = true,
    },
    {
        "akinsho/bufferline.nvim",
        version = "*",
        dependencies = "nvim-tree/nvim-web-devicons",
        event = "VeryLazy",
        config = function()
            require("bufferline").setup({
                options = {
                    mode = "buffers",
                    style_preset = require("bufferline").style_preset.default,
                    themable = true,
                    numbers = "none",
                    close_command = "bdelete! %d",
                    right_mouse_command = "bdelete! %d",
                    left_mouse_command = "buffer %d",
                    middle_mouse_command = nil,
                    indicator = {
                        icon = "▎",
                        style = "icon",
                    },
                    buffer_close_icon = "󰅖",
                    modified_icon = "●",
                    close_icon = "",
                    left_trunc_marker = "",
                    right_trunc_marker = "",
                    max_name_length = 18,
                    max_prefix_length = 15,
                    truncate_names = true,
                    tab_size = 18,
                    diagnostics = "nvim_lsp",
                    diagnostics_update_in_insert = false,
                    diagnostics_indicator = function(count, level, diagnostics_dict, context)
                        local icon = level:match("error") and " " or " "
                        return " " .. icon .. count
                    end,
                    color_icons = true,
                    show_buffer_icons = true,
                    show_buffer_close_icons = true,
                    show_close_icon = true,
                    show_tab_indicators = true,
                    show_duplicate_prefix = true,
                    persist_buffer_sort = true,
                    separator_style = "thin",
                    enforce_regular_tabs = false,
                    always_show_bufferline = true,
                    hover = {
                        enabled = true,
                        delay = 200,
                        reveal = { "close" },
                    },
                    offsets = {
                        {
                            filetype = "NvimTree",
                            text = "File Explorer",
                            text_align = "left",
                            separator = true,
                        },
                    },
                },
            })
        end,
    },
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig",
        },
        config = function()
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

            require("mason-lspconfig").setup({
                ensure_installed = {
                    -- C# / .NET
                    "csharp_ls",
                },
                automatic_installation = true,
            })
        end,
    },
    {
        "saghen/blink.cmp",
        dependencies = {
            "rafamadriz/friendly-snippets",
        },
        version = "v0.*",
        event = "InsertEnter",
        opts = {
            keymap = {
                preset = "enter",
                ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                ["<C-e>"] = { "hide" },
                ["<C-y>"] = { "select_and_accept" },

                ["<Up>"] = { "select_prev", "fallback" },
                ["<Down>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
                ["<C-n>"] = { "select_next", "fallback" },

                ["<C-b>"] = { "scroll_documentation_up", "fallback" },
                ["<C-f>"] = { "scroll_documentation_down", "fallback" },

                ["<Tab>"] = { "snippet_forward", "fallback" },
                ["<S-Tab>"] = { "snippet_backward", "fallback" },
            },

            appearance = {
                use_nvim_cmp_as_default = true,
                nerd_font_variant = "mono",
            },

            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },

            completion = {
                accept = {
                    auto_brackets = {
                        enabled = true,
                    },
                },
                menu = {
                    border = "rounded",
                    draw = {
                        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
                    },
                },
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 500,
                    window = {
                        border = "rounded",
                    },
                },
                ghost_text = {
                    enabled = false,
                },
            },

            signature = {
                enabled = true,
                window = {
                    border = "rounded",
                },
            },
        },
        opts_extend = { "sources.default" },
    },
    -- nvim v0.8.0
    {
        "kdheepak/lazygit.nvim",
        lazy = true,
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
        },
        {
            "folke/noice.nvim",
            event = "VeryLazy",
            dependencies = {
                -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
                "MunifTanjim/nui.nvim",
                -- OPTIONAL:
                --   `nvim-notify` is only needed, if you want to use the notification view.
                --   If not available, we use `mini` as the fallback
                "rcarriga/nvim-notify",
            },
            opts = {
                lsp = {
                    override = {
                        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                        ["vim.lsp.util.stylize_markdown"] = true,
                        ["cmp.entry.get_documentation"] = true,
                    },
                },
                routes = {
                    {
                        filter = {
                            event = "msg_show",
                            any = {
                                { find = "%d+L, %d+B" },
                                { find = "; after #%d+" },
                                { find = "; before #%d+" },
                            },
                        },
                        view = "mini",
                    },
                },
                presets = {
                    bottom_search = true,
                    command_palette = true,
                    long_message_to_split = true,
                },
            },
            -- stylua: ignore
            keys = {
                { "<leader>sn", "", desc = "+noice"},
                { "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
                { "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
                { "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
                { "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
                { "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
                { "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)" },
                { "<c-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll Forward", mode = {"i", "n", "s"} },
                { "<c-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll Backward", mode = {"i", "n", "s"}},
            },
            config = function(_, opts)
                -- HACK: noice shows messages from before it was enabled,
                -- but this is not ideal when Lazy is installing plugins,
                -- so clear the messages in this case.
                if vim.o.filetype == "lazy" then
                    vim.cmd([[messages clear]])
                end
                require("noice").setup(opts)
            end,
        }
    }})
