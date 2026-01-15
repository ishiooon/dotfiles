local function setup_codex()
  -- Codex 統合の初期化を行い、ユーザーコマンドなどを登録する
  -- Codex 統合の初期化処理を実行する
  require("codex").setup()
end

local function build_codex_spec()
  local local_dir = "/home/dev_local/dev_plugin/codex.nvim"
  -- ローカル開発版の有無を確認するため、ファイルシステムを参照する
  local stat = (vim.uv or vim.loop).fs_stat(local_dir)
  if stat and stat.type == "directory" then
    return {
      -- ローカルで開発中の codex.nvim を直接読み込む
      dir = local_dir,
      name = "codex.nvim",
      config = setup_codex,
    }
  end

  return {
    -- ローカル開発版が無い場合は GitHub から取得する
    "ishiooon/codex.nvim",
    name = "codex.nvim",
    config = setup_codex,
  }
end

return {
  build_codex_spec(),
}
