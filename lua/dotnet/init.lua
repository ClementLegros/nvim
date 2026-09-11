-- A small .NET solution/project GUI for Neovim.
--
-- Everything here is a thin wrapper over the `dotnet` CLI — no language server,
-- no MSBuild parsing, no background daemon. The CLI already knows how to create
-- a solution, add a project to it and scaffold a file; what it lacks is a way to
-- reach those from inside the editor without retyping paths, which is what this
-- module is.
--
-- Entry points: the :Dotnet command and <leader>n (see setup below).

local actions = require("dotnet.actions")
local menu = require("dotnet.menu")

local M = {}

--- Open the main menu.
function M.open()
    menu.open({
        title = ".NET",
        items = {
            { key = "s", label = "Nouvelle solution", handler = actions.new_solution },
            { key = "p", label = "Nouveau projet", handler = actions.new_project },
            { key = "a", label = "Ajouter au .sln", handler = actions.add_projects },
            { key = "f", label = "Nouveau fichier", handler = actions.new_file },
            { key = "r", label = "Référence projet", handler = actions.add_reference },
            { key = "n", label = "Package NuGet", handler = actions.add_package },
            { separator = true },
            { key = "q", label = "Fermer", handler = nil },
        },
    })
end

function M.setup()
    vim.api.nvim_create_user_command("Dotnet", M.open, { desc = ".NET: open the solution menu" })
    vim.keymap.set("n", "<leader>n", M.open, { desc = ".NET menu" })
end

return M
