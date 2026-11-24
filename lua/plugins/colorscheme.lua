-- Le thème visuel est délégué au gestionnaire de thèmes de ~/.config/themes.
--
-- Partage des rôles :
--   - ici : le plugin (catppuccin) et tout ce qui ne dépend pas du thème —
--     transparence, intégrations des autres plugins ;
--   - themes/current/nvim.lua : ce qui en dépend. Le fichier *renvoie* une
--     table d'options catppuccin (en pratique `color_overrides`), fusionnée
--     par-dessus les options communes ci-dessous.
--
-- Sans ce fichier, on obtient catppuccin mocha tel quel — ce dépôt est aussi
-- utilisé seul (github.com/ClementLegros/nvim), sans le dossier themes/.
--
-- Rechargement à chaud : `:ThemeReload`. `theme-switch <nom>` l'appelle dans
-- chaque nvim ouvert, il n'y a donc plus besoin de les relancer.
--
-- Note : le *plugin* de colorscheme reste déclaré dans plugins/init.lua.

local M = {}

local theme_file = vim.fn.expand("~/.config/themes/current/nvim.lua")

local function base_options()
    return {
        flavour = "mocha",
        -- Le fond visible est celui de kitty, translucide.
        transparent_background = true,
        term_colors = true,
        integrations = {
            blink_cmp = true,
            telescope = { enabled = true },
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
    }
end

-- Lit le thème actif et (ré)applique la colorscheme. Rejouable à volonté :
-- catppuccin.setup() repart de ses défauts à chaque appel, donc la palette
-- d'un thème ne déteint pas sur le suivant, et il recompile ses highlights
-- dès que les options changent.
function M.apply()
    local opts = base_options()

    if vim.uv.fs_stat(theme_file) then
        local ok, theme = pcall(dofile, theme_file)
        if ok and type(theme) == "table" then
            opts = vim.tbl_deep_extend("force", opts, theme)
        else
            local why = ok and "il doit renvoyer une table d'options" or tostring(theme)
            vim.notify("thème externe ignoré (" .. theme_file .. ") : " .. why, vim.log.levels.WARN)
        end
    end

    require("catppuccin").setup(opts)
    -- Déclenche aussi ColorScheme : lualine (theme = "auto") et bufferline
    -- s'en servent pour recalculer leurs propres couleurs.
    vim.cmd.colorscheme("catppuccin")
end

vim.api.nvim_create_user_command("ThemeReload", M.apply, {
    desc = "Relit ~/.config/themes/current/nvim.lua et réapplique la colorscheme",
})

M.apply()

return M
