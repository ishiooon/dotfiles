local M = {}

-- Deno の標準的なインストール先を PATH の先頭へ追加し、denops.vim が見つけやすい状態にする。
function M.build_deno_path(home_dir, current_path)
  return table.concat({
    home_dir .. "/.local/bin",
    home_dir .. "/.deno/bin",
    current_path,
  }, ":")
end

-- deno が実行できる場合だけ denops.vim の参照先へ設定し、存在しない固定パスによる警告を避ける。
function M.apply_deno_path(vim_api)
  local home_dir = vim_api.fn.expand("~")
  local current_path = vim_api.fn.getenv("PATH")
  vim_api.fn.setenv("PATH", M.build_deno_path(home_dir, current_path))

  local deno_path = vim_api.fn.exepath("deno")
  if deno_path == "" then
    return nil
  end

  vim_api.g.denops_deno = deno_path
  vim_api.g["denops#deno"] = deno_path
  return deno_path
end

return M
