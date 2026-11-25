-- プラグイン本体の保存処理を実行せず、公開関数の呼び出しと互換性の警告だけを再現する。
local setup_calls, profile_calls, warnings = 0, 0, {}
package.loaded.triforce = {
  setup = function(options)
    setup_calls = setup_calls + 1
    if options and options.keymap then
      warnings[#warnings + 1] = "keymap は非推奨の設定です。"
    end
  end,
  show_profile = function()
    profile_calls = profile_calls + 1
  end,
}

-- 実際の設定を読み込み、非推奨オプションによる起動時の警告が出ないことを確かめる。
vim.g.mapleader = " "
local spec = dofile(vim.env.ROOT_DIR .. "/.config/nvim/lua/plugins/triforce.lua")[1]
spec.config()
assert(setup_calls == 1, "Triforce の初期化が実行されていません。")
assert(#warnings == 0, "Triforce の初期化で非推奨オプションの警告が発生します。")

-- Neovim 自身にキー入力を処理させ、従来の操作からプロフィール表示へ到達できることを確かめる。
local mapping = vim.fn.maparg("<leader>tp", "n", false, true)
assert(not vim.tbl_isempty(mapping), "プロフィールを表示するキーマップがありません。")
local keys = vim.api.nvim_replace_termcodes("<Space>tp", true, false, true)
vim.api.nvim_feedkeys(keys, "xt", false)
assert(profile_calls == 1, "<leader>tp からプロフィールを表示できません。")

print("PASS: Triforce は警告なく初期化され、<leader>tp でプロフィールを表示できます。")
