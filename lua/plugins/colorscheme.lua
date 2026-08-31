-- Le thème visuel est délégué au gestionnaire de thèmes de ~/.config/themes :
-- `themes/current/nvim.lua` fait le setup du plugin et applique la colorscheme.
-- Bascule : `theme-switch <nom>` (nécessite de relancer nvim).
--
-- Repli sur catppuccin si ce fichier est absent — ce dépôt est aussi utilisé
-- seul (github.com/ClementLegros/nvim), sans le dossier themes/.
--
-- Note : le *plugin* de colorscheme reste déclaré dans plugins/init.lua. Un
-- thème qui utilise une autre colorscheme doit donc y ajouter son plugin.

local theme = vim.fn.expand("~/.config/themes/current/nvim.lua")

if vim.uv.fs_stat(theme) then
    local ok, err = pcall(dofile, theme)
    if ok then
        return
    end
    vim.notify("thème externe illisible : " .. tostring(err), vim.log.levels.WARN)
end

require("catppuccin").setup({ flavour = "mocha", transparent_background = true })
vim.cmd.colorscheme("catppuccin")
