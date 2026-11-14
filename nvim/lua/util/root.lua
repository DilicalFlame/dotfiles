-- Project root detection: LSP workspace -> .git/lua marker -> cwd. Cached per buffer.
local M = {}

M.spec = { "lsp", { ".git", "lua" }, "cwd" }
local ignore_lsp = { "copilot" }
local cache = {}

local function norm(path)
  return path and path ~= "" and vim.fs.normalize(path) or nil
end

local function bufpath(buf)
  -- terminals, pickers etc. have pseudo-paths (term://...); only real files count
  if vim.bo[buf].buftype ~= "" then
    return nil
  end
  return norm(vim.api.nvim_buf_get_name(buf))
end

function M.cwd()
  return norm(vim.uv.cwd()) or ""
end

local detectors = {
  cwd = function()
    return { M.cwd() }
  end,
  lsp = function(buf)
    local path = bufpath(buf)
    if not path then
      return {}
    end
    local roots = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf })) do
      if not vim.tbl_contains(ignore_lsp, client.name) then
        for _, ws in ipairs(client.config.workspace_folders or {}) do
          roots[#roots + 1] = vim.uri_to_fname(ws.uri)
        end
        if client.root_dir then
          roots[#roots + 1] = client.root_dir
        end
      end
    end
    return vim.tbl_filter(function(r)
      r = norm(r)
      return r and path:find(r, 1, true) == 1
    end, roots)
  end,
}

local function by_pattern(buf, patterns)
  local found = vim.fs.find(patterns, { path = bufpath(buf) or vim.uv.cwd(), upward = true })[1]
  return found and { vim.fs.dirname(found) } or {}
end

local function detect(buf)
  for _, spec in ipairs(M.spec) do
    local paths = detectors[spec] and detectors[spec](buf) or by_pattern(buf, spec)
    paths = vim.tbl_map(norm, paths)
    table.sort(paths, function(a, b)
      return #a > #b
    end)
    if paths[1] then
      return paths[1]
    end
  end
  return M.cwd()
end

---@param opts? {buf?: number, normalize?: boolean}
function M.get(opts)
  opts = opts or {}
  local buf = opts.buf or vim.api.nvim_get_current_buf()
  cache[buf] = cache[buf] or detect(buf)
  local root = cache[buf]
  if opts.normalize or vim.fn.has("win32") == 0 then
    return root
  end
  return (root:gsub("/", "\\"))
end

function M.git()
  local root = M.get()
  local git = vim.fs.find(".git", { path = root, upward = true })[1]
  return git and vim.fs.dirname(git) or root
end

vim.api.nvim_create_autocmd({ "LspAttach", "BufWritePost", "DirChanged", "BufEnter" }, {
  group = vim.api.nvim_create_augroup("RootCache", { clear = true }),
  callback = function(ev)
    cache[ev.buf] = nil
  end,
})

return M
