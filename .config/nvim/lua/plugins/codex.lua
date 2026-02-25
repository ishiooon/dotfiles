local CODEX_NAME = "codex.nvim"
local LOCAL_CODEX_DIR = "/home/dev_local/dev_plugin/codex.nvim"
local REMOTE_CODEX_REPO = "ishiooon/codex.nvim"

local function setup_codex()
  -- Codex 統合を初期化し、コマンドやキーマップなどの登録を実行します
  require("codex").setup()
end

local function get_fs_api()
  return vim.uv or vim.loop
end

local function is_local_codex_available()
  local fs_api = get_fs_api()
  local stat = fs_api and fs_api.fs_stat and fs_api.fs_stat(LOCAL_CODEX_DIR) or nil
  return stat ~= nil and stat.type == "directory"
end

local function build_local_spec()
  return {
    dir = LOCAL_CODEX_DIR,
    name = CODEX_NAME,
    config = setup_codex,
  }
end

local function build_remote_spec()
  return {
    REMOTE_CODEX_REPO,
    name = CODEX_NAME,
    config = setup_codex,
  }
end

local function build_codex_spec()
  if is_local_codex_available() then
    return build_local_spec()
  end

  return build_remote_spec()
end

return { build_codex_spec() }
