-- Inline diagnostics
require("tiny-inline-diagnostic").setup()

-- Bufferline
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
        diagnostics_indicator = function(count, level, _, _)
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
    },
})

-- Statusline
--
-- theme = "auto" is what keeps this in step with ~/.config/themes: lualine
-- resolves `lualine.themes.<vim.g.colors_name>` at setup, and the colorscheme
-- has already been applied by then (plugins/init.lua requires colorscheme
-- before ui). With catppuccin active that lands on the catppuccin-mocha theme
-- the colorscheme plugin itself ships, so `theme-switch` needs no lualine entry.
--
-- Flat separators rather than powerline arrows, to match the bufferline above
-- (separator_style = "thin"). Swap in "" / "" for the arrow look.
require("lualine").setup({
    options = {
        theme = "auto",
        icons_enabled = true,
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
        -- One statusline for the whole window layout (sets laststatus=3),
        -- mirroring the single global bufferline at the top.
        globalstatus = true,
        always_divide_middle = true,
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = {
            { "filename", path = 1, symbols = { modified = "●", readonly = "", unnamed = "[No Name]" } },
            {
                "diagnostics",
                sources = { "nvim_diagnostic" },
                symbols = { error = " ", warn = " ", hint = " ", info = " " },
            },
        },
        lualine_x = { "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
    -- Non-file windows get a stripped-down line instead of a misleading one.
    extensions = { "oil", "mason", "quickfix", "trouble" },
})
