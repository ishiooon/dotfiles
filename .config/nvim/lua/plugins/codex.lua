local CODEX_NAME = "codex.nvim"
local LOCAL_CODEX_DIR_CANDIDATES = {
  "/Users/ishiooon/develop/codex.nvim",
  "/home/dev_local/dev_plugin/codex.nvim",
}
local REMOTE_CODEX_REPO = "ishiooon/codex.nvim"

local function setup_codex()
  -- Codex 統合を初期化し、コマンドやキーマップなどの登録を実行します
  require("codex").setup()
  local ok, codex_wezterm = pcall(require, "config.codex_wezterm")
  if ok and type(codex_wezterm.setup) == "function" then
    -- codex.nvimの内部状態をWezTermのタブタイトルへ反映します。
    codex_wezterm.setup()
  end
end

local function get_fs_api()
  return vim.uv or vim.loop
end

local function find_local_codex_dir()
  local fs_api = get_fs_api()
  if not (fs_api and fs_api.fs_stat) then
    return nil
  end

  for _, dir in ipairs(LOCAL_CODEX_DIR_CANDIDATES) do
    -- ローカル開発版が存在する環境では、その作業ツリーを直接読み込みます。
    local stat = fs_api.fs_stat(dir)
    if stat ~= nil and stat.type == "directory" then
      return dir
    end
  end

  return nil
end

local function build_local_spec(local_dir)
  return {
    dir = local_dir,
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
  local local_dir = find_local_codex_dir()
  if local_dir then
    return build_local_spec(local_dir)
  end

  return build_remote_spec()
end

return { build_codex_spec() }
