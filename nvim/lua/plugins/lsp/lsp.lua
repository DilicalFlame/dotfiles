local python_env = require("util.python_env")
local icons = require("config.icons")

---@param kind string code action kind, e.g. "source.organizeImports"
local function action(kind)
  return function()
    vim.lsp.buf.code_action({ apply = true, context = { only = { kind }, diagnostics = {} } })
  end
end

---@return boolean true if any attached client offers a code action kind starting with `prefix`
local function has_action(buf, prefix)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
    local kinds = vim.tbl_get(client, "server_capabilities", "codeActionProvider", "codeActionKinds") or {}
    for _, reg in ipairs(client.dynamic_capabilities:get("codeActionProvider", { bufnr = buf }) or {}) do
      vim.list_extend(kinds, vim.tbl_get(reg, "registerOptions", "codeActionKinds") or {})
    end
    for _, k in ipairs(kinds) do
      if k:find("^" .. vim.pesc(prefix) .. "%.?") then
        return true
      end
    end
  end
  return false
end

--- Run a workspace/executeCommand on the first matching client.
local function execute(opts)
  local client = vim.lsp.get_clients({ bufnr = 0, name = opts.name })[1]
  if client then
    client:exec_cmd({ command = opts.command, arguments = opts.arguments, title = opts.title }, { bufnr = 0 })
  end
end

local kind_filter = {
  "Class", "Constructor", "Enum", "Field", "Function", "Interface", "Method", "Module", "Namespace", "Package",
  "Property", "Struct", "Trait",
}

-- Buffer-local LSP keymaps, only set when the attached server supports the feature (`has`).
-- stylua: ignore
local keys = {
  { "<leader>cl", function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
  { "gd", function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition", has = "definition" },
  { "gr", function() Snacks.picker.lsp_references() end, desc = "References", nowait = true },
  { "gI", function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
  { "gy", function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
  { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
  { "K", vim.lsp.buf.hover, desc = "Hover" },
  { "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
  { "<c-k>", vim.lsp.buf.signature_help, mode = "i", desc = "Signature Help", has = "signatureHelp" },
  { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "x" }, has = "codeAction" },
  { "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "x" }, has = "codeLens" },
  { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", has = "codeLens" },
  { "<leader>cR", function() Snacks.rename.rename_file() end, desc = "Rename File", has = { "workspace/didRenameFiles", "workspace/willRenameFiles" } },
  { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
  { "<leader>cA", action("source"), desc = "Source Action", has = "codeAction" },
  { "<leader>ss", function() Snacks.picker.lsp_symbols({ filter = { default = kind_filter, markdown = false, help = false } }) end, desc = "LSP Symbols", has = "documentSymbol" },
  { "<leader>sS", function() Snacks.picker.lsp_workspace_symbols({ filter = { default = kind_filter, markdown = false, help = false } }) end, desc = "LSP Workspace Symbols", has = "workspace/symbols" },
  { "gai", function() Snacks.picker.lsp_incoming_calls() end, desc = "C[a]lls Incoming", has = "callHierarchy/incomingCalls" },
  { "gao", function() Snacks.picker.lsp_outgoing_calls() end, desc = "C[a]lls Outgoing", has = "callHierarchy/outgoingCalls" },
  { "]]", function() Snacks.words.jump(vim.v.count1) end, has = "documentHighlight", desc = "Next Reference", enabled = function() return Snacks.words.is_enabled() end },
  { "[[", function() Snacks.words.jump(-vim.v.count1) end, has = "documentHighlight", desc = "Prev Reference", enabled = function() return Snacks.words.is_enabled() end },
  { "<a-n>", function() Snacks.words.jump(vim.v.count1, true) end, has = "documentHighlight", desc = "Next Reference", enabled = function() return Snacks.words.is_enabled() end },
  { "<a-p>", function() Snacks.words.jump(-vim.v.count1, true) end, has = "documentHighlight", desc = "Prev Reference", enabled = function() return Snacks.words.is_enabled() end },
  { "<leader>co", action("source.organizeImports"), desc = "Organize Imports", has = "codeAction", enabled = function(buf) return has_action(buf, "source.organizeImports") end },
}

---@param filter vim.lsp.get_clients.Filter
---@param spec table[]
local function set_keys(filter, spec)
  for _, k in ipairs(spec) do
    local methods = k.has and (type(k.has) == "string" and { k.has } or k.has) or { false }
    for _, method in ipairs(methods) do
      local f = vim.deepcopy(filter)
      if method then
        f.method = method:find("/") and method or ("textDocument/" .. method)
      end
      Snacks.keymap.set(k.mode or "n", k[1], k[2], { desc = k.desc, nowait = k.nowait, lsp = f, enabled = k.enabled })
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      { "mason-org/mason-lspconfig.nvim", config = function() end }, -- set up manually below
    },
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.Info,
          },
        },
      },
      inlay_hints = { enabled = true, exclude = { "vue" } },
      folds = { enabled = true },

      -- Server name = lspconfig name. All are installed by mason-lspconfig.
      servers = {
        ["*"] = {
          capabilities = {
            workspace = { fileOperations = { didRename = true, willRename = true } },
          },
        },

        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              codeLens = { enable = true },
              completion = { callSnippet = "Replace" },
              doc = { privateName = { "^_" } },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
          },
        },

        pyright = {
          handlers = { ["$/progress"] = function() end },
          settings = {
            python = {
              analysis = {
                -- Keep completions/hover/import intelligence but avoid strict typing noise.
                typeCheckingMode = "off",
                diagnosticMode = "openFilesOnly",
              },
            },
          },
          before_init = function(_, config)
            local root_dir = config.root_dir or vim.fn.getcwd()
            local python_path = python_env.python_for_root(root_dir)
            if not python_path then
              python_env.activate(root_dir)
              python_path = python_env.python_for_root(root_dir)
            end
            if python_path then
              config.settings = config.settings or {}
              config.settings.python = config.settings.python or {}
              config.settings.python.pythonPath = python_path
            end
          end,
        },

        -- TypeScript / JavaScript
        vtsls = {
          filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = { enableServerSideFuzzyMatch = true },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = { completeFunctionCalls = true },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
          -- stylua: ignore
          keys = {
            { "gD", function()
                local params = vim.lsp.util.make_position_params(0, "utf-16")
                execute({ name = "vtsls", command = "typescript.goToSourceDefinition", arguments = { params.textDocument.uri, params.position } })
              end, desc = "Goto Source Definition" },
            { "gR", function()
                execute({ name = "vtsls", command = "typescript.findAllFileReferences", arguments = { vim.uri_from_bufnr(0) } })
              end, desc = "File References" },
            { "<leader>cM", action("source.addMissingImports.ts"), desc = "Add missing imports" },
            { "<leader>cD", action("source.fixAll.ts"), desc = "Fix all diagnostics" },
            { "<leader>cV", function()
                execute({ name = "vtsls", command = "typescript.selectTypeScriptVersion", title = "Select TypeScript Version" })
              end, desc = "Select TS workspace version" },
          },
        },

        eslint = {
          settings = {
            -- helps eslint find the eslintrc when it's in a subfolder instead of the cwd root
            workingDirectories = { mode = "auto" },
            format = true,
          },
        },

        jsonls = {
          -- schemastore is loaded lazily, only when a json server starts
          before_init = function(_, new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = { json = { format = { enable = true }, validate = { enable = true } } },
        },

        svelte = {},
        taplo = {}, -- TOML

        -- Installed/managed elsewhere; keep mason-lspconfig from auto-enabling them.
        stylua = { enabled = false }, -- formatter, not an LSP
        rust_analyzer = { enabled = false }, -- rustaceanvim drives rust-analyzer (plugins/lsp/rust.lua)
      },
    },
    config = function(_, opts)
      -- diagnostics
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

      -- inlay hints
      if opts.inlay_hints.enabled then
        Snacks.util.lsp.on({ method = "textDocument/inlayHint" }, function(buffer)
          if
            vim.api.nvim_buf_is_valid(buffer)
            and vim.bo[buffer].buftype == ""
            and not vim.tbl_contains(opts.inlay_hints.exclude, vim.bo[buffer].filetype)
          then
            vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
          end
        end)
      end

      -- LSP folds (switches foldmethod to "expr" only for servers that support it)
      if opts.folds.enabled then
        Snacks.util.lsp.on({ method = "textDocument/foldingRange" }, function()
          vim.wo[0][0].foldmethod = "expr"
          vim.wo[0][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
        end)
      end

      -- vtsls: "move to file" refactoring + share TS settings with JS
      local vtsls = opts.servers.vtsls
      vtsls.settings.javascript = vim.tbl_deep_extend("force", {}, vtsls.settings.typescript, vtsls.settings.javascript or {})
      Snacks.util.lsp.on({ name = "vtsls" }, function(_, client)
        client.commands["_typescript.moveToFileRefactoring"] = function(command)
          local act, uri, range = unpack(command.arguments)
          local function move(newf)
            client:request("workspace/executeCommand", { command = command.command, arguments = { act, uri, range, newf } })
          end
          local fname = vim.uri_to_fname(uri)
          client:request("workspace/executeCommand", {
            command = "typescript.tsserverRequest",
            arguments = {
              "getMoveToRefactoringFileSuggestions",
              {
                file = fname,
                startLine = range.start.line + 1,
                startOffset = range.start.character + 1,
                endLine = range["end"].line + 1,
                endOffset = range["end"].character + 1,
              },
            },
          }, function(_, result)
            local files = result.body.files
            table.insert(files, 1, "Enter new path...")
            vim.ui.select(files, {
              prompt = "Select move destination:",
              format_item = function(f)
                return vim.fn.fnamemodify(f, ":~:.")
              end,
            }, function(f)
              if f and f:find("^Enter new path") then
                vim.ui.input({
                  prompt = "Enter move destination:",
                  default = vim.fn.fnamemodify(fname, ":h") .. "/",
                  completion = "file",
                }, function(newf)
                  return newf and move(newf)
                end)
              elseif f then
                move(f)
              end
            end)
          end)
        end
      end)

      -- svelte: load the TS plugin so .svelte imports resolve in vtsls
      vtsls.settings.vtsls.tsserver = vtsls.settings.vtsls.tsserver or {}
      vtsls.settings.vtsls.tsserver.globalPlugins = {
        {
          name = "typescript-svelte-plugin",
          location = vim.fn.expand("$MASON/packages/svelte-language-server/node_modules/typescript-svelte-plugin"),
          enableForWorkspaceTypeScriptVersions = true,
        },
      }

      -- keymaps: global ones, then per-server ones
      set_keys({}, keys)
      for name, server in pairs(opts.servers) do
        if name ~= "*" and type(server) == "table" and server.keys then
          set_keys({ name = name }, server.keys)
          server.keys = nil
        end
      end

      -- server configs
      vim.lsp.config("*", opts.servers["*"])
      local names, disabled = {}, {}
      for name, server in pairs(opts.servers) do
        if name ~= "*" then
          if server.enabled == false then
            disabled[#disabled + 1] = name
          else
            vim.lsp.config(name, server)
            names[#names + 1] = name
          end
        end
      end

      -- ensure_installed: my servers. automatic_enable: everything mason has installed (e.g. clangd) except `disabled`.
      require("mason-lspconfig").setup({
        ensure_installed = names,
        automatic_enable = { exclude = vim.list_extend(disabled, { "ts_ls", "tsserver", "bacon_ls" }) },
      })
    end,
  },

  -- JSON schemas for jsonls
  { "b0o/SchemaStore.nvim", lazy = true, version = false },
}
