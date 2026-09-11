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
lua/dotnet/                  Menu .NET (module local, pas un plugin vim.pack)
  init.lua                   Entrées du menu, :Dotnet, <leader>n
  menu.lua                   La fenêtre flottante générique
  cli.lua                    Exécution asynchrone de `dotnet`
  context.lua                Où suis-je : solution, projet, namespace
  solution.lua               Ce que la solution contient (dotnet sln list)
  project.lua                Graphe des références projet-à-projet
  templates.lua              Catalogue `dotnet new`
  actions.lua                Les six actions du menu
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

roslyn_ls : quand un fichier est ajouté au projet (création, renommage), les
buffers déjà ouverts gardaient des erreurs CS0246 jusqu'à un `:e`. Neovim ne
redemandait que les diagnostics « workspace » ; `lua/config/lsp.lua` redemande
aussi ceux de chaque document ouvert à chaque `workspace/diagnostic/refresh`.

Diagnostic utile : `:checkhealth vim.lsp`.

Dépendances externes : `lazygit` (pour `<leader>gg`), un Nerd Font, `git`.

## Menu .NET

`<leader>n` (ou `:Dotnet`) ouvre un menu flottant :

| Touche | Action |
|--------|--------|
| `s` | Nouvelle solution (`.slnx` par défaut, `.sln` au choix) |
| `p` | Nouveau projet — 7 templates courants + le catalogue complet |
| `a` | Ajouter au `.sln` les projets présents sur disque mais absents |
| `f` | Nouveau fichier — class / interface / record / enum / struct |
| `r` | Référence projet-à-projet |
| `n` | Package NuGet (recherche sur nuget.org) |

Tout passe par la CLI `dotnet` : pas de serveur, pas de démon, pas d'analyse
MSBuild. Les champs de saisie acceptent un **chemin** et pas seulement un nom —
`src/Api` crée le projet `Api` sous `src/`, `Services/Billing/Invoice` crée les
dossiers et y place `Invoice.cs`.

Deux endroits font mieux que la CLI, délibérément :

- **Le namespace.** `dotnet new class` écrit `namespace <RacineDuProjet>;` en
  ignorant les dossiers, sans option pour corriger, et avec un BOM. Le fichier
  est donc écrit directement, avec le namespace dérivé de l'arborescence
  (vérifié : 81 des 82 fichiers d'ApiConverter, le dernier étant `Program.cs`).
- **Les cycles de références.** `dotnet add reference` accepte une référence
  circulaire sans broncher (exit 0) et le build casse ensuite avec `MSB4006`.
  Le menu n'affiche que les projets qui ne peuvent pas déjà atteindre la source,
  transitivement.

Après chaque action, les buffers oil concernés sont réaffichés et les fichiers
modifiés rechargés (`:checktime <bufnr>`, la forme globale ne touchant pas les
buffers cachés).

Dépendance externe : le SDK `dotnet` sur le PATH.

## Migration

Ancienne config lazy.nvim conservée dans l'historique git. Le dossier
`~/.local/share/nvim/lazy` (plugins lazy.nvim) peut être supprimé manuellement.
