-- C# source operations shared by the menu (actions.lua) and the oil hooks
-- (oil.lua): the body of a new file, and the type a file is named after —
-- finding it, renaming it everywhere, finding who still uses it.
--
-- The roslyn_ls requests here are SYNCHRONOUS (request_sync). The oil hooks
-- have no choice: OilActionsPre is the last moment the server still knows the
-- file under its old path, and oil moves it the moment the hook returns. The
-- menu uses the same code for a single, explicit action, where a fraction of a
-- second of blocking is not worth a second, callback-shaped copy.

local M = {}

-- Generous: a rename walks every reference in the solution.
local TIMEOUT_MS = 10000

local TITLE = ".NET"

--- Build a new file's body, and say which line the cursor belongs on.
---
--- @param keyword string   class | interface | record | enum | struct
--- @param namespace string|nil
--- @return string[] lines, integer cursor_line
function M.scaffold(keyword, name, namespace)
    local lines = {}

    -- File-scoped, matching 69 of the 72 namespaced files in this codebase (the
    -- three block-scoped ones are EF-generated migrations).
    if namespace then
        table.insert(lines, "namespace " .. namespace .. ";")
        table.insert(lines, "")
    end

    table.insert(lines, "public " .. keyword .. " " .. name)
    table.insert(lines, "{")
    table.insert(lines, "")
    table.insert(lines, "}")

    -- The blank line between the braces: where you would start typing anyway.
    return lines, #lines - 1
end

-- The symbol kinds a file can be named after. Records come back as Class
-- (record struct as Struct), so they need no entry of their own.
local TYPE_KINDS = {
    [vim.lsp.protocol.SymbolKind.Class] = true,
    [vim.lsp.protocol.SymbolKind.Interface] = true,
    [vim.lsp.protocol.SymbolKind.Enum] = true,
    [vim.lsp.protocol.SymbolKind.Struct] = true,
}

--- Where the type called `name` is declared, from a documentSymbol answer.
---
--- Searched recursively: the types are CHILDREN of the namespace symbol
--- (measured, file-scoped namespace included). A generic type is reported as
--- "Repository<T>" while its file is Repository.cs, hence the stripped suffix.
---
--- @return lsp.Position|nil
local function find_type(symbols, name)
    for _, symbol in ipairs(symbols) do
        if TYPE_KINDS[symbol.kind] and symbol.name:gsub("<.*$", "") == name then
            -- DocumentSymbol carries selectionRange (the identifier itself);
            -- the flat SymbolInformation form only has a location.
            return (symbol.selectionRange or symbol.location.range).start
        end
        local found = find_type(symbol.children or {}, name)
        if found then
            return found
        end
    end
    return nil
end

--- Every buffer a WorkspaceEdit touches, in either of its two shapes.
local function edited_buffers(edit)
    local uris = {}
    for uri in pairs(edit.changes or {}) do
        uris[uri] = true
    end
    for _, change in ipairs(edit.documentChanges or {}) do
        if change.textDocument then
            uris[change.textDocument.uri] = true
        end
    end

    local out = {}
    for uri in pairs(uris) do
        table.insert(out, vim.uri_to_bufnr(uri))
    end
    return out
end

--- One synchronous request, with its three ways of failing folded into a
--- message: timeout, server error, or (for the caller to judge) a null result.
--- @return any result, string|nil err
local function request(client, bufnr, method, params)
    local response, err = client:request_sync(method, params, TIMEOUT_MS, bufnr)
    if not response then
        return nil, ("roslyn_ls : %s (%s)"):format(err or "pas de réponse", method)
    end
    if response.err then
        return nil, "roslyn_ls : " .. response.err.message
    end
    return response.result, nil
end

--- Where the type named after the file is declared, if there is one.
--- @return lsp.Position|nil position, string|nil err
local function locate(client, bufnr, name)
    local symbols, err = request(client, bufnr, "textDocument/documentSymbol", {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
    })
    if err then
        return nil, err
    end
    return find_type(symbols or {}, name), nil
end

--- @class dotnet.RenameResult
--- @field renamed boolean   false: no type called `old` in the file (Program.cs)
--- @field written integer   files saved with the rename
--- @field pending string[]  files renamed in their buffer but left unsaved

--- Rename the type `old` declared in `bufnr` to `new`, across the solution,
--- and save what changed. The file itself is NOT renamed — that is the caller's
--- job (vim.lsp.util.rename for the menu, oil for the hook).
---
--- The buffer at `bufnr` is always saved when it was edited, unsaved changes
--- included: its file is about to move, and what moves is what is on disk.
---
--- @return dotnet.RenameResult|nil result, string|nil err
function M.rename_type(client, bufnr, old, new)
    local position, err = locate(client, bufnr, old)
    if err then
        return nil, err
    end

    -- Program.cs, or a file holding several small types: nothing is named
    -- after it, so there is nothing to rename but the file.
    if not position then
        return { renamed = false, written = 0, pending = {} }
    end

    -- Snapshot BEFORE the edit: which buffers already existed and which held
    -- unsaved work. Both decide what happens to a buffer afterwards.
    local loaded, modified = {}, {}
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        loaded[b] = vim.api.nvim_buf_is_loaded(b)
        modified[b] = vim.bo[b].modified
    end

    local edit
    edit, err = request(client, bufnr, "textDocument/rename", {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = position,
        newName = new,
    })
    if err then
        return nil, err
    end

    -- An invalid identifier is refused WITHOUT an error: measured, "2Bad" comes
    -- back as a null result. Nothing has changed at this point.
    if not edit then
        return nil, ("roslyn_ls refuse de renommer %s en %s (nom de type C# invalide ?)"):format(old, new)
    end

    vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding)

    -- Saved, because a rename is only real once every reference is on disk:
    -- `dotnet build` reads files, not buffers. The exception is a buffer that
    -- ALREADY had unsaved changes — writing it would commit work in progress
    -- along with the rename, so it is left to the user and named in the report.
    local result = { renamed = true, written = 0, pending = {} }
    for _, b in ipairs(edited_buffers(edit)) do
        if b ~= bufnr and modified[b] then
            table.insert(result.pending, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t"))
        else
            vim.api.nvim_buf_call(b, function()
                vim.cmd("silent write")
            end)
            result.written = result.written + 1

            -- apply_workspace_edit loads every file it edits into a LISTED
            -- buffer: renaming a widely used type would fill the bufferline with
            -- files nobody opened. Those go away again; the edit is on disk.
            if b ~= bufnr and not loaded[b] then
                vim.api.nvim_buf_delete(b, {})
            end
        end
    end

    return result, nil
end

--- The files, other than its own, that use the type `name` declared in `bufnr`.
--- @return string[]|nil paths, string|nil err  (empty list: none, or no such type)
function M.users_of_type(client, bufnr, name)
    local position, err = locate(client, bufnr, name)
    if err then
        return nil, err
    end
    if not position then
        return {}, nil
    end

    local locations
    locations, err = request(client, bufnr, "textDocument/references", {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = position,
        context = { includeDeclaration = false },
    })
    if err then
        return nil, err
    end

    local own = vim.uri_from_bufnr(bufnr)
    local seen, out = {}, {}
    for _, location in ipairs(locations or {}) do
        if location.uri ~= own and not seen[location.uri] then
            seen[location.uri] = true
            table.insert(out, vim.uri_to_fname(location.uri))
        end
    end
    table.sort(out)
    return out, nil
end

--- Report a rename the way both callers want it said.
--- @param result dotnet.RenameResult
function M.report_rename(old, new, result)
    if not result.renamed then
        vim.notify(
            ("%s.cs → %s.cs (aucun type %s dans le fichier : seul le fichier est renommé)"):format(old, new, old),
            vim.log.levels.INFO,
            { title = TITLE }
        )
        return
    end

    vim.notify(
        ("%s.cs → %s.cs, type %s renommé dans %d fichier%s"):format(
            old,
            new,
            new,
            result.written,
            result.written > 1 and "s" or ""
        ),
        vim.log.levels.INFO,
        { title = TITLE }
    )
    if #result.pending > 0 then
        vim.notify(
            "Modifiés mais NON enregistrés (changements en cours) : " .. table.concat(result.pending, ", "),
            vim.log.levels.WARN,
            { title = TITLE }
        )
    end
end

return M
