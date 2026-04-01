-- テスト対象の Lua モジュールを読み込めるように、dotfiles 配下の設定を探索対象へ追加する。
local root_dir = vim.env.ROOT_DIR
package.path = table.concat({
  root_dir .. "/.config/nvim/lua/?.lua",
  root_dir .. "/.config/nvim/lua/?/init.lua",
  package.path,
}, ";")

local refresh = require("config.neo_tree_git_refresh")

-- 単純な値比較の失敗時に差分を読み取りやすく表示する。
local function assert_equal(expected, actual, message)
  if expected ~= actual then
    error(message .. "\n期待値: " .. tostring(expected) .. "\n実際値: " .. tostring(actual))
  end
end

-- 配列順を含めて比較し、更新対象の選定結果がぶれないことを確認する。
local function assert_table_equal(expected, actual, message)
  assert_equal(#expected, #actual, message .. "\n件数が一致しません。")

  for index, expected_value in ipairs(expected) do
    assert_equal(
      expected_value,
      actual[index],
      message .. "\n位置 " .. tostring(index) .. " の値が一致しません。"
    )
  end
end

-- 同一タブで表示中の filesystem と git_status だけが更新対象になることを確認する。
local visible_sources = refresh.collect_refreshable_sources({
  { name = "filesystem", tabid = 4, path = "/repo", winid = 11 },
  { name = "git_status", tabid = 4, path = "/repo", winid = 12 },
  { name = "buffers", tabid = 4, path = "/repo", winid = 13 },
  { name = "filesystem", tabid = 3, path = "/repo", winid = 14 },
  { name = "filesystem", tabid = 4, path = nil, winid = 15 },
}, 4, function(state)
  return state.winid == 11 or state.winid == 12 or state.winid == 13
end)

assert_table_equal(
  { "filesystem", "git_status" },
  visible_sources,
  "現在のタブで表示中の NeoTree ソースだけを更新対象にできませんでした。"
)
assert_equal(
  true,
  refresh.should_fire_refresh(visible_sources),
  "表示中の NeoTree が存在する場合は更新を実行するべきです。"
)

-- 画面に出ていない NeoTree は再描画しないようにし、不要な処理を避ける。
local hidden_sources = refresh.collect_refreshable_sources({
  { name = "filesystem", tabid = 4, path = "/repo", winid = 21 },
  { name = "git_status", tabid = 4, path = "/repo", winid = 22 },
}, 4, function()
  return false
end)

assert_table_equal(
  {},
  hidden_sources,
  "非表示の NeoTree ソースまで更新対象に含めてしまいました。"
)
assert_equal(
  false,
  refresh.should_fire_refresh(hidden_sources),
  "表示中の NeoTree が無い場合は更新を実行するべきではありません。"
)

-- 外部端末や別タブから戻った場合も拾えるよう、想定したイベントだけを公開する。
local trigger_events = refresh.get_trigger_events()
assert_table_equal(
  { "FocusGained", "ShellCmdPost", "TabEnter", "TermClose" },
  trigger_events,
  "外部の Git 操作を拾うための自動更新イベントが想定どおりではありません。"
)

print("PASS: NeoTree の Git 状態更新判定は表示中のソースだけを対象にできました。")
