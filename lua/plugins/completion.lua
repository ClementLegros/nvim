require("blink.cmp").setup({
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
                -- `label_description` renders item.labelDetails.description.
                -- Measured: csharp_ls, lua_ls and ts_ls all send labelDetails=nil,
                -- so this column is always empty here. Kept because it costs no
                -- width when empty and populates for servers that do send it.
                -- The type info for these three comes from the docs window below.
                columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
            },
        },
        documentation = {
            auto_show = true,
            -- All servers configured here advertise resolveProvider=true: they send
            -- bare labels and only fill in `detail` / `documentation` when the
            -- client asks via completionItem/resolve. blink calls resolve ONLY for
            -- this documentation window, never for the menu rows, so this window is
            -- the only place the signature can appear (`Guid` -> "readonly struct
            -- System.Guid"). At 500ms it stayed hidden while typing, which made the
            -- menu look like plain text with no LSP content behind it.
            auto_show_delay_ms = 50,
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
})
