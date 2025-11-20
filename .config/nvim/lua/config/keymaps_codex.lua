-- Codex 関連のキーマップと補助関数をまとめ、側作用（通知・送信）を局所化する
local M = {}

-- Codex 操作の有無を事前確認する（副作用: 見つからない場合は通知を出す）
local function get_codex_action(action_key, label)
  local ok, codex = pcall(require, "codex")
  if not ok or not codex then
    vim.notify("codex: モジュールが見つかりません", vim.log.levels.WARN)
    return nil
  end
  local action = action_key == "toggle" and codex.toggle or (codex.actions and codex.actions[action_key])
  if type(action) ~= "function" then
    vim.notify(string.format("codex: %s が見つかりません", label or action_key), vim.log.levels.WARN)
    return nil
  end
  return action
end

-- Codex をトグルする（副作用: Codex ウィンドウの開閉）
local function toggle_codex()
  local toggle = get_codex_action("toggle", "toggle")
  if toggle then
    toggle()
  end
end

-- ビジュアル選択を Codex へ送信する（副作用: Codex バッファへ送信）
local function send_visual_selection_to_codex()
  local send_selection = get_codex_action("send_selection", "actions.send_selection")
  if send_selection then
    send_selection()
  end
end

-- ccresume-codex を npx で起動する（副作用: 右側にターミナルを開き外部プロセスを開始）
local function run_ccresume_codex()
  if vim.fn.executable("npx") == 0 then
    vim.notify("npx が見つかりません。Node.js/npm の導入を確認してください", vim.log.levels.ERROR)
    return
  end
  local prev_splitright = vim.o.splitright
  vim.o.splitright = true
  vim.cmd("vsplit")
  vim.o.splitright = prev_splitright
  vim.cmd("terminal npx --yes @nogataka/ccresume-codex@latest")
  vim.cmd("wincmd L")
  vim.cmd("vertical resize 35")
  vim.cmd("startinsert")
  vim.notify("ccresume-codex を右側ターミナルで起動しました (npx)", vim.log.levels.INFO)
end

-- neo-tree で現在カーソルが当たっているノードのパスを取得する（副作用: 取得できない場合は通知）
local function get_current_neotree_path()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if not ok or not manager or type(manager.get_state) ~= "function" then
    vim.notify("neo-tree: 選択中のファイルを取得できません", vim.log.levels.WARN)
    return nil
  end
  local state = manager.get_state(vim.b.neo_tree_source or "filesystem")
  if not state or not state.tree or type(state.tree.get_node) ~= "function" then
    vim.notify("neo-tree: ノードを検出できません", vim.log.levels.WARN)
    return nil
  end
  local node = state.tree:get_node()
  if not node or type(node.get_id) ~= "function" then
    vim.notify("neo-tree: カーソル位置のノード取得に失敗しました", vim.log.levels.WARN)
    return nil
  end
  local path = node:get_id()
  if type(path) ~= "string" or path == "" then
    vim.notify("neo-tree: ファイル名が空です", vim.log.levels.WARN)
    return nil
  end
  return path
end

-- neo-tree 上で @ファイルパス を Codex へ送信する（副作用: Codex バッファへ送信）
local function send_neotree_file_to_codex()
  local send = get_codex_action("send", "actions.send")
  if not send then
    return
  end
  local path = get_current_neotree_path()
  if not path then
    return
  end
  -- 自動送信はせず、入力欄にパスだけ送る
  send(path .. "\n", { submit = false })
end

-- エントリーポイント: Codex 周りのキーマップを登録する
function M.setup()
  vim.keymap.set("n", "<leader>cc", toggle_codex, { desc = "Codex: Toggle" })
  vim.keymap.set("n", "<leader>cr", run_ccresume_codex, { desc = "Codex: Run ccresume (npx)" })
  vim.keymap.set("v", "<leader>cs", send_visual_selection_to_codex, { desc = "Codex: Send selection" })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "neo-tree",
    callback = function(event)
      vim.keymap.set("n", "<leader>cs", send_neotree_file_to_codex, { buffer = event.buf, desc = "Codex: Neo-tree でファイル送信" })
    end,
  })
end

return M
