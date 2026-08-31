# Neovim config

Configuration Neovim (>= 0.12) utilisant l'API native **`vim.pack`** comme
gestionnaire de plugins (migrée depuis lazy.nvim) et l'**API LSP native**
(`vim.lsp.config` / `vim.lsp.enable`).

## Structure

```
init.lua                     Point d'entrée (ordre de chargement)
lua/config/
  options.lua                Options + <leader>
  keymaps.lua                Keymaps généraux (buffers, splits, diagnostics) + LSP
  lsp.lua                    LSP natif : diagnostics + config/enable des serveurs
lua/plugins/
  init.lua                   vim.pack.add(...) → la liste des plugins
  colorscheme.lua            catppuccin
  ui.lua                     bufferline, tiny-inline-diagnostic
  editor.lua                 oil, telescope, nvim-window, lazygit
  mason.lua                  installation des serveurs LSP
  completion.lua             blink.cmp
```

## Gestion des plugins

- **Installer** : ajouter une entrée dans `lua/plugins/init.lua` puis relancer
  Neovim (`:restart`). vim.pack clone les plugins manquants au démarrage.
- **Mettre à jour** : `:lua vim.pack.update()` → ouvre un buffer de diff.
  `:write` pour confirmer, `:quit` pour annuler.
- **Supprimer** : retirer l'entrée de `init.lua`, `:restart`, puis
  `:lua vim.pack.del({ "nom-du-plugin" })`.
- Les révisions verrouillées sont dans `nvim-pack-lock.json` (auto-généré).

## LSP

Les serveurs sont **installés** par mason (`:Mason`, liste dans
`lua/plugins/mason.lua`) et **activés** nativement dans `lua/config/lsp.lua` via
`vim.lsp.enable()`.

`nvim-lspconfig` est présent uniquement comme **source de données** : il n'est
jamais `require()`'d. Depuis sa v2 il fournit des specs `lsp/<serveur>.lua` que
Neovim découvre tout seul sur le runtimepath (cmd, filetypes, root_markers,
init_options). `lua/config/lsp.lua` ne contient donc que les écarts par rapport
à ces valeurs par défaut.

Serveurs activés : `csharp_ls`, `lua_ls`, `ts_ls`, `eslint`, `html`, `cssls`,
`jsonls`, `tailwindcss`, `intelephense`.

Attention : les noms de paquets mason ne sont pas les noms de serveurs
lspconfig (`csharp_ls` → `csharp-language-server`, `cssls` → `css-lsp`). Les
deux listes doivent rester synchronisées.

Les keymaps LSP sont dans `lua/config/keymaps.lua` et sont mappés
inconditionnellement — comme les défauts de Neovim (`grn`/`gra`/`grr`). Dans un
buffer sans serveur, `gd` affiche donc « not supported by any server activated
for this buffer » au lieu de retomber silencieusement sur le `gd` de Vim.

Diagnostic utile : `:checkhealth vim.lsp`.

Dépendances externes : `lazygit` (pour `<leader>gg`), un Nerd Font, `git`.

## Migration

Ancienne config lazy.nvim conservée dans l'historique git. Le dossier
`~/.local/share/nvim/lazy` (plugins lazy.nvim) peut être supprimé manuellement.
