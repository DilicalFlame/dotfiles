local M = {}

local uv = vim.uv or vim.loop
local is_windows = vim.fn.has("win32") == 1
local path_list_sep = is_windows and ";" or ":"

local env_dir_candidates = { ".venv", "venv", "env" }
local root_markers = {
  ".git",
  "pyproject.toml",
  "requirements.txt",
  "setup.py",
  "setup.cfg",
  "Pipfile",
  "poetry.lock",
}

local state = {
  root = nil,
  python = nil,
  venv = nil,
  original_virtual_env = vim.env.VIRTUAL_ENV,
  last_bin_dir = nil,
}

local function fs_stat(path)
  if not path or path == "" then
    return nil
  end
  return uv.fs_stat(path)
end

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.fs.normalize(path)
end

local function is_uri(path)
  return path and path:match("^%a[%w+.-]*://") ~= nil
end

local function same_path(a, b)
  if not a or not b then
    return false
  end
  local na = normalize(a)
  local nb = normalize(b)
  if not na or not nb then
    return false
  end
  if is_windows then
    return na:lower() == nb:lower()
  end
  return na == nb
end

local function split_path(path)
  if not path or path == "" then
    return {}
  end

  local parts = {}
  for part in path:gmatch("([^" .. path_list_sep .. "]+)") do
    parts[#parts + 1] = part
  end
  return parts
end

local function set_path_with_env_bin(bin_dir)
  local entries = split_path(vim.env.PATH or "")
  local updated = {}

  for _, entry in ipairs(entries) do
    local is_previous_env_bin = state.last_bin_dir and same_path(entry, state.last_bin_dir)
    local is_new_env_bin = bin_dir and same_path(entry, bin_dir)
    if not is_previous_env_bin and not is_new_env_bin then
      updated[#updated + 1] = entry
    end
  end

  if bin_dir then
    table.insert(updated, 1, bin_dir)
  end

  vim.env.PATH = table.concat(updated, path_list_sep)
  state.last_bin_dir = bin_dir
end

local function python_from_venv(venv_dir)
  local python_relpath = is_windows and "Scripts/python.exe" or "bin/python"
  local python = vim.fs.joinpath(venv_dir, python_relpath)
  if fs_stat(python) then
    return python
  end
  return nil
end

function M.project_root(startpath)
  local path = startpath
  if not path or path == "" then
    path = vim.api.nvim_buf_get_name(0)
  end
  if is_uri(path) then
    path = nil
  end
  if not path or path == "" then
    path = vim.fn.getcwd()
  end

  local path_stat = fs_stat(path)
  local search_dir = path
  if path_stat and path_stat.type == "file" then
    search_dir = vim.fs.dirname(path)
  end

  local marker = vim.fs.find(root_markers, { path = search_dir, upward = true })[1]
  if marker then
    return vim.fs.dirname(marker)
  end

  return vim.fn.getcwd()
end

function M.detect(root)
  for _, env_name in ipairs(env_dir_candidates) do
    local env_dir = vim.fs.joinpath(root, env_name)
    local env_dir_stat = fs_stat(env_dir)
    if env_dir_stat and env_dir_stat.type == "directory" then
      local python = python_from_venv(env_dir)
      if python then
        return python, env_dir
      end
    end
  end

  return nil, nil
end

function M.python_for_root(root)
  local normalized_root = normalize(root)
  if not normalized_root then
    return nil
  end

  if state.root == normalized_root then
    return state.python
  end

  local python = M.detect(normalized_root)
  return normalize(python)
end

local function set_process_environment(python, venv_dir)
  if python and venv_dir then
    local bin_dir = vim.fs.dirname(python)
    vim.env.VIRTUAL_ENV = venv_dir
    set_path_with_env_bin(bin_dir)
    vim.g.python3_host_prog = python
    return
  end

  set_path_with_env_bin(nil)
  vim.env.VIRTUAL_ENV = state.original_virtual_env
  vim.g.python3_host_prog = nil
end

function M.activate(startpath)
  local root = normalize(M.project_root(startpath))
  local python, venv_dir = M.detect(root)

  python = normalize(python)
  venv_dir = normalize(venv_dir)

  if state.root == root and state.python == python and state.venv == venv_dir then
    return {
      root = root,
      python = python,
      venv = venv_dir,
      changed = false,
    }
  end

  state.root = root
  state.python = python
  state.venv = venv_dir

  set_process_environment(python, venv_dir)

  vim.g.project_python_path = python

  return {
    root = root,
    python = python,
    venv = venv_dir,
    changed = true,
  }
end

function M.current()
  return {
    root = state.root,
    python = state.python,
    venv = state.venv,
  }
end

return M