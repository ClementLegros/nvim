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

-- Per-window filename float (top-right corner of each window).
--
-- This is the counterpart of the globalstatus lualine above: with a single
-- statusline for the whole layout, a split gives no clue which file lives in
-- which window. Incline puts the name back on each window — and only when it is
-- actually needed (see hide.only_win below).
local devicons = require("nvim-web-devicons")

require("incline").setup({
    hide = {
        -- With a single window lualine already names the file, so the float
        -- would just be a duplicate. Set to false to always show it.
        only_win = true,
        -- Step aside when the cursor reaches the line the float sits on.
        cursorline = "focused_win",
    },
    window = {
        margin = { horizontal = 1, vertical = 0 },
        padding = 1,
        placement = { horizontal = "right", vertical = "top" },
    },
    ignore = {
        -- oil buffers are directories: the name and the devicon are meaningless.
        filetypes = { "oil" },
    },
    -- Linked to an existing group rather than hardcoded, so the float follows
    -- ~/.config/themes like everything else. Not NormalFloat (incline's default)
    -- because catppuccin's transparent_background leaves it without a background,
    -- which would drop the filename straight onto the buffer text.
    highlight = {
        groups = {
            -- default = true: a theme that ships its own Incline groups wins.
            InclineNormal = { group = "Pmenu", default = true },
            InclineNormalNC = { group = "Pmenu", default = true },
        },
    },
    render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then
            filename = "[No Name]"
        end

        -- Same icons as the lualine diagnostics component, most severe first.
        -- Only the fg of DiagnosticSign* applies, so the float's own background
        -- (InclineNormal / InclineNormalNC) shows through.
        local icons = { Error = "", Warn = "", Info = "", Hint = "" }
        local diagnostics = {}
        for _, severity in ipairs({ "Error", "Warn", "Info", "Hint" }) do
            local n = #vim.diagnostic.get(props.buf, { severity = vim.diagnostic.severity[severity:upper()] })
            if n > 0 then
                table.insert(diagnostics, { icons[severity] .. " " .. n .. " ", group = "DiagnosticSign" .. severity })
            end
        end

        local ft_icon, ft_color = devicons.get_icon_color(filename)
        local modified = vim.bo[props.buf].modified

        return {
            diagnostics,
            ft_icon and { ft_icon .. " ", guifg = props.focused and ft_color or nil } or "",
            {
                filename,
                gui = modified and "bold,italic" or "bold",
                -- Dim the unfocused windows: which one is active stays readable
                -- at a glance even with several splits open.
                group = not props.focused and "Comment" or nil,
            },
            modified and { " ●" } or "",
        }
    end,
})
