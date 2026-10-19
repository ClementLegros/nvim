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
  dotnet.lua                 easy-dotnet + nvim-dap + nvim-dap-ui (run / debug / tests .NET)
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

## Menu .NET

Le menu .NET (`<leader>n`), le renommage / déplacement de fichiers
C# via roslyn_ls et les actions déclenchées depuis oil sont dans leur propre
dépôt, pour pouvoir être partagés :
[dotnet-menu.nvim](https://github.com/ClementLegros/dotnet-menu.nvim).

Installé par `vim.pack` (`lua/plugins/init.lua`), initialisé dans `init.lua`.
Il corrige aussi les erreurs CS0246 qui restaient affichées jusqu'à un `:e`
après l'ajout d'un fichier au projet (option `roslyn_diagnostics`).

La commande `:Dotnet` appartient à easy-dotnet (voir ci-dessous) : les deux
plugins la définissent et le dernier `setup()` l'emporte. C'est pour ça que
`plugins.dotnet` est chargé après dotnet-menu dans `init.lua`.

## Debug .NET

`lua/plugins/dotnet.lua` : [easy-dotnet.nvim](https://github.com/GustavEikaas/easy-dotnet.nvim)
(build / run avec les launch profiles, debug, test runner) +
[nvim-dap](https://github.com/mfussenegger/nvim-dap) +
[nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui).

Dépendance externe : le serveur EasyDotnet, qui fournit aussi netcoredbg
(mason n'a donc pas besoin de l'installer) :

```sh
dotnet tool install -g EasyDotnet
```

L'interface dap-ui s'ouvre au démarrage d'une session et se ferme à la fin.

### Raccourcis (façon Visual Studio)

| Touche | Action |
| --- | --- |
| `<F5>` | Démarrer le debug du projet par défaut / continuer si une session tourne |
| `<C-F5>` | Lancer sans debugger |
| `<S-F5>` | Arrêter le debug |
| `<F9>` | Basculer un breakpoint |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<S-F11>` | Step out |

Au premier `<F5>`, easy-dotnet demande quel projet utiliser par défaut et le
mémorise. Selon le terminal, les F-keys avec Shift / Ctrl arrivent en `<F17>` /
`<F23>` / `<F29>` : elles sont mappées aussi.

### Raccourcis hors F-keys

| Touche | Action |
| --- | --- |
| `<leader>b` | Basculer un breakpoint |
| `<leader>B` | Breakpoint conditionnel (demande la condition) |
| `<leader>u` | Afficher / masquer l'interface dap-ui |
| `<leader>k` | Évaluer l'expression sous le curseur (ou la sélection) |

Pas de famille `<leader>d…` : `<leader>d` ouvre le float de diagnostic.

### Tests

| Touche | Action |
| --- | --- |
| `<leader>To` | Ouvrir / fermer le test runner |
| `<leader>Tr` | Lancer le test sous le curseur |
| `<leader>Td` | Debugger le test sous le curseur |
| `<leader>Ta` | Lancer tous les tests du fichier |
| `<leader>Tp` | Afficher la sortie du test |

Les maps `<leader>T…` (sauf `<leader>To`) ne sont définies que dans les fichiers
qui contiennent des tests. Dans la fenêtre du test runner, ce sont les
raccourcis par défaut d'easy-dotnet.

## Migration

Ancienne config lazy.nvim conservée dans l'historique git. Le dossier
`~/.local/share/nvim/lazy` (plugins lazy.nvim) peut être supprimé manuellement.
