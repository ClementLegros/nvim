-- .NET run / debug / test runner: easy-dotnet.nvim + nvim-dap + nvim-dap-ui.
--
-- Split of roles with dotnet-menu.nvim (init.lua):
--   * dotnet-menu : oil, rename / move of .cs files (type + namespace follow),
--                   new solution / project / file, references, NuGet.
--   * easy-dotnet : build / run with launch profiles, debugging, test runner,
--                   EF, user secrets, outdated packages.
--
-- Three things keep them from stepping on each other:
--
--   * lsp.enabled = false. easy-dotnet otherwise starts its OWN Roslyn, in a
--     client named `easy_dotnet`, while dotnet-menu only talks to a client
--     named `roslyn_ls` (config/lsp.lua). Debugging and the test runner do not
--     go through that client — they go through the EasyDotnet server
--     (`dotnet tool install -g EasyDotnet`), which also ships netcoredbg, so
--     mason does not need to install it.
--   * :Dotnet. Both plugins create it, unconditionally, and the last setup
--     wins. easy-dotnet has to own it: the nvim-dap configuration it registers
--     starts a session by running `:Dotnet debug profile`. So this file is
--     required after dotnet-menu's setup; the menu stays on <leader>n.
--   * auto_bootstrap_namespace = false. Filling a new .cs file is dotnet-menu's
--     job (menu + oil); two mechanisms writing the same empty file is one too
--     many.

local map = vim.keymap.set

require("easy-dotnet").setup({
    lsp = { enabled = false },
    auto_bootstrap_namespace = { enabled = false },
    picker = "telescope",
    debugger = {
        -- Only feeds the easy-dotnet_cpu / easy-dotnet_mem dapui widgets, which
        -- the layout below does not show — no point sampling for nothing.
        mem_cpu_usage = false,
    },
    test_runner = {
        -- The *_from_buffer maps are buffer-local, set in every file that holds
        -- tests. Their defaults (<leader>r / d / t / p) would shadow
        -- <leader>d (diagnostic float) and make <leader>rn and every <leader>t…
        -- (trouble) wait out `timeoutlen` in those files. Moved under
        -- <leader>T. The maps INSIDE the test runner window keep their defaults.
        mappings = {
            run_test_from_buffer = { lhs = "<leader>Tr", desc = "Test: run test under cursor" },
            debug_test_from_buffer = { lhs = "<leader>Td", desc = "Test: debug test under cursor" },
            run_all_tests_from_buffer = { lhs = "<leader>Ta", desc = "Test: run all tests in file" },
            peek_stack_trace_from_buffer = { lhs = "<leader>Tp", desc = "Test: peek output" },
        },
    },
})

map("n", "<leader>To", "<cmd>Dotnet testrunner<cr>", { desc = "Test: toggle test runner" })

-- Debug UI: variables, call stack, breakpoints and watches on the left, REPL and
-- program console at the bottom (dapui's default layout). Values also show at
-- the end of the lines, drawn by easy-dotnet itself — no nvim-dap-virtual-text.
local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

dap.listeners.after.event_initialized["dapui"] = function()
    dapui.open()
end
dap.listeners.before.event_terminated["dapui"] = function()
    dapui.close()
end
dap.listeners.before.event_exited["dapui"] = function()
    dapui.close()
end

-- The text must not be empty: a sign without text is never placed, so nvim-dap
-- sees no breakpoint at all and the program runs straight through.
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
vim.fn.sign_define("DapLogPoint", { text = "◇", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

-- Visual Studio keys.
--
-- F5 starts the persisted default project with its launch profile, like VS;
-- the first time, easy-dotnet asks which project that is. With a session
-- already running it continues instead. In a PowerShell buffer it debugs the
-- current script instead, through the `ps1` adapter of powershell.nvim (see
-- plugins/powershell.lua) — the stepping keys below are plain nvim-dap and
-- serve both.
--
-- Shifted / Ctrl'd F-keys are mapped twice: depending on the terminal they
-- arrive as <S-F5> or as <F17> (F5 + 12), <C-F5> or <F29> (F5 + 24).
map("n", "<F5>", function()
    if dap.session() then
        dap.continue()
    elseif vim.bo.filetype == "ps1" then
        -- Not dap.continue(): that would ask which of powershell.nvim's three
        -- configurations to use on every start.
        dap.run({
            name = "PowerShell: Launch Current File",
            type = "ps1",
            request = "launch",
            script = "${file}",
        })
    else
        require("easy-dotnet").debug_default()
    end
end, { desc = "Debug: start / continue" })
map("n", "<C-F5>", function()
    require("easy-dotnet").run_default()
end, { desc = "Run without debugging" })
map("n", "<F29>", function()
    require("easy-dotnet").run_default()
end, { desc = "Run without debugging" })
map("n", "<S-F5>", dap.terminate, { desc = "Debug: stop" })
map("n", "<F17>", dap.terminate, { desc = "Debug: stop" })
map("n", "<F9>", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
map("n", "<F10>", dap.step_over, { desc = "Debug: step over" })
map("n", "<F11>", dap.step_into, { desc = "Debug: step into" })
map("n", "<S-F11>", dap.step_out, { desc = "Debug: step out" })
map("n", "<F23>", dap.step_out, { desc = "Debug: step out" })

-- Same actions away from the F-keys. Not under <leader>d: that is the
-- diagnostic float, and a <leader>d… family would make it wait `timeoutlen`.
map("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: toggle breakpoint" })
map("n", "<leader>B", function()
    dap.set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "Debug: conditional breakpoint" })
map("n", "<leader>u", dapui.toggle, { desc = "Debug: toggle UI" })
map({ "n", "v" }, "<leader>k", dapui.eval, { desc = "Debug: evaluate expression" })
