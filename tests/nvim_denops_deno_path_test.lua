-- テスト対象の Lua モジュールを読み込めるように、dotfiles 配下の設定を探索対象へ追加する。
local root_dir = vim.env.ROOT_DIR
package.path = table.concat({
  root_dir .. "/.config/nvim/lua/?.lua",
  root_dir .. "/.config/nvim/lua/?/init.lua",
  package.path,
}, ";")

local denops = require("config.denops")

-- 単純な値比較の失敗時に差分を読み取りやすく表示する。
local function assert_equal(expected, actual, message)
  if expected ~= actual then
    error(message .. "\n期待値: " .. tostring(expected) .. "\n実際値: " .. tostring(actual))
  end
end

-- Deno のインストール先候補を PATH の先頭へ追加し、既存 PATH も保持する。
local deno_path = denops.build_deno_path("/Users/example", "/usr/bin:/bin")
assert_equal(
  "/Users/example/.local/bin:/Users/example/.deno/bin:/usr/bin:/bin",
  deno_path,
  "Deno の探索先を PATH の先頭へ追加できませんでした。"
)

-- 実行できる deno が見つかった場合だけ denops.vim に明示する。
local configured = {}
denops.apply_deno_path({
  fn = {
    expand = function()
      return "/Users/example"
    end,
    getenv = function()
      return "/usr/bin:/bin"
    end,
    setenv = function(name, value)
      configured.path_name = name
      configured.path_value = value
    end,
    exepath = function(name)
      if name == "deno" then
        return "/usr/local/bin/deno"
      end
      return ""
    end,
  },
  g = configured,
})

assert_equal("PATH", configured.path_name, "PATH の更新先が想定と異なります。")
assert_equal("/usr/local/bin/deno", configured.denops_deno, "denops_deno に実行可能な deno を設定できませんでした。")
assert_equal("/usr/local/bin/deno", configured["denops#deno"], "denops#deno に実行可能な deno を設定できませんでした。")

-- deno が見つからない場合は、存在しないパスを denops.vim に渡さない。
local missing = {}
denops.apply_deno_path({
  fn = {
    expand = function()
      return "/Users/example"
    end,
    getenv = function()
      return "/usr/bin:/bin"
    end,
    setenv = function() end,
    exepath = function()
      return ""
    end,
  },
  g = missing,
})

assert_equal(nil, missing.denops_deno, "存在しない deno を denops_deno に設定してはいけません。")
assert_equal(nil, missing["denops#deno"], "存在しない deno を denops#deno に設定してはいけません。")

print("PASS: denops.vim は実行可能な deno だけを参照します。")
