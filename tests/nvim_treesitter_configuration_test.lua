-- 標準のファイル種別別プラグインからの呼び出しを止め、対象の設定だけを検証する。
vim.cmd("filetype plugin indent off")

-- 新しい公開 API だけを持つプラグインを用意し、通信やパーサーの保存を防ぐ。
local state = { installed = {}, requested = {}, callbacks = {}, highlighted = {}, setups = 0 }
local parsers = {}
for _, language in ipairs({ "bash", "c", "html", "lua", "markdown", "vim", "vimdoc",
    "tsx", "typescript", "regex", "blade", "php", "php_only", "javascript", "ruby", "python" }) do
    parsers[language] = {}
end
package.loaded["nvim-treesitter.parsers"] = parsers
package.loaded["nvim-treesitter"] = {
    setup = function() state.setups = state.setups + 1 end,
    install = function(languages)
        for _, language in ipairs(languages) do
            state.requested[language] = (state.requested[language] or 0) + 1
        end
        return {
            await = function(_, callback)
                table.insert(state.callbacks, { languages = languages, callback = callback })
            end,
            wait = function(_, timeout)
                assert(timeout >= 0 and timeout <= 1000, "待機時間が指定の上限を超えています。")
                if state.wait_error then error(state.wait_error) end
                return state.wait_result ~= false
            end,
        }
    end,
    get_installed = function() return vim.tbl_keys(state.installed) end,
    update = function()
        return { wait = function(_, timeout)
            assert(timeout == 300000, "更新処理の待機時間が5分に設定されていません。")
            if state.update_error then error(state.update_error) end
            return state.update_result ~= false
        end }
    end,
}

-- パーサーの導入前後を切り替え、バッファへの色分け開始と失敗を再現する。
vim.treesitter.start = function(buffer, language)
    if not state.installed[language] then error("パーサーがありません: " .. language) end
    state.highlighted[buffer] = language
    vim.bo[buffer].syntax = ""
end
vim.treesitter.query.get = function(language, query)
    if state.installed[language] and query == "indents" then return {} end
end
package.path = vim.env.ROOT_DIR .. "/.config/nvim/lua/?.lua;" .. package.path

-- メモリー上でファイル種別を設定し、実際の FileType イベントを発生させる。
local function create_buffer(filetype)
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.bo[buffer].filetype = filetype
    return buffer
end

-- 自動導入の完了通知を配送して、非同期処理後の画面設定まで検証する。
local function complete_installations()
    local callbacks = state.callbacks
    state.callbacks = {}
    for _, task in ipairs(callbacks) do
        for _, language in ipairs(task.languages) do state.installed[language] = true end
        task.callback(nil, true)
    end
    vim.wait(100, function() return false end)
end

local existing_buffer = create_buffer("lua")
local spec = require("plugins.treesitter")[1]

-- ビルド時の更新完了を待ち、取得失敗やタイムアウトをプラグイン管理機能へ伝える。
spec.build()
state.update_result = false
assert(not pcall(spec.build), "ビルド時のパーサー更新失敗を成功扱いしています。")
state.update_result = nil
state.update_error = "更新処理がタイムアウトしました。"
assert(not pcall(spec.build), "ビルド時のタイムアウトを成功扱いしています。")
state.update_error = nil

spec.config(spec, spec.opts or {})
assert(state.setups == 1, "現行の Treesitter API で初期設定できませんでした。")
local lua_buffer = create_buffer("lua")
assert(state.highlighted[lua_buffer] == nil, "未導入のパーサーで色分けを開始しています。")
complete_installations()
assert(state.highlighted[lua_buffer] == "lua", "パーサー導入後のバッファで色分けが始まりません。")
assert(state.highlighted[existing_buffer] == "lua", "設定読み込み前に開いたバッファに色分けが反映されません。")
assert(vim.bo[lua_buffer].indentexpr ~= "", "Lua の自動インデントが有効になりません。")

-- 従来の対象言語を維持し、設定済み言語と開いたファイルの導入が重複しないことを確認する。
for _, language in ipairs({ "bash", "c", "html", "lua", "markdown", "vim", "vimdoc",
    "tsx", "typescript", "regex", "blade" }) do
    assert(state.requested[language] == 1, language .. " のパーサー導入が欠落または重複しています。")
end
assert(vim.filetype.match({ filename = "view.blade.php" }) == "blade",
    "Blade テンプレートのファイル種別を判定できません。")
local blade_buffer = create_buffer("blade")
assert(state.highlighted[blade_buffer] == "blade", "Blade の色分けが始まりません。")

-- Ruby は標準インデントを維持し、Ruby と Markdown の正規表現による色分けを併用する。
local ruby_buffer = create_buffer("ruby")
vim.bo[ruby_buffer].indentexpr = "GetRubyIndent()"
complete_installations()
assert(state.highlighted[ruby_buffer] == "ruby", "Ruby の色分けが始まりません。")
assert(vim.bo[ruby_buffer].indentexpr == "GetRubyIndent()", "Ruby の標準インデントが変更されました。")
assert(vim.bo[ruby_buffer].syntax == "ruby", "Ruby の正規表現による色分けが無効です。")
local markdown_buffer = create_buffer("markdown")
assert(vim.bo[markdown_buffer].syntax == "markdown", "Markdown の正規表現による色分けが無効です。")

-- プラグインの画面用バッファでは、ファイル用のパーサーを取得しない。
local scratch_buffer = vim.api.nvim_create_buf(false, true)
vim.bo[scratch_buffer].filetype = "python"
assert(state.requested.python == nil, "画面用のバッファでパーサーを取得しています。")

-- 既定の一覧にない対応言語は自動導入し、同時に開いた複数バッファにも反映する。
local python_buffer = create_buffer("python")
local second_python_buffer = create_buffer("python")
assert(state.requested.python == 1, "同じ言語の自動導入が重複しています。")
complete_installations()
assert(state.highlighted[python_buffer] == "python" and state.highlighted[second_python_buffer] == "python",
    "自動導入後、同じ言語の全バッファで色分けを開始できません。")

-- 未対応のファイル種別を開いても、導入要求やエラーを発生させない。
create_buffer("unknown_dotfiles_test")
assert(state.requested.unknown_dotfiles_test == nil, "未対応言語の導入を試みています。")

-- 初期設定から実際に開始した取得処理を待ち、必要なパーサーの不足も失敗として通知する。
local config = require("config.treesitter")
config.wait_for_parsers(1000)
state.installed.bash = nil
assert(not pcall(config.wait_for_parsers, 1000), "必要なパーサーが未導入なのに成功扱いしています。")
state.installed.bash = true
state.wait_result = false
assert(not pcall(config.wait_for_parsers, 1000), "パーサーの取得失敗を成功扱いしています。")
state.wait_result = nil
state.wait_error = "取得処理がタイムアウトしました。"
assert(not pcall(config.wait_for_parsers, 1000), "タイムアウトを成功扱いしています。")
state.wait_error = nil

-- 設定処理の呼び忘れは、未実行のまま成功したように見せず明示的に失敗させる。
package.loaded["config.treesitter"] = nil
local uninitialized = require("config.treesitter")
assert(not pcall(uninitialized.wait_for_parsers, 1000), "初期設定が未実行なのに成功扱いしています。")
assert(vim.v.errmsg == "", "イベント処理中にエラーが発生しました: " .. vim.v.errmsg)
print("PASS: Treesitter の初期設定、自動導入、色分け、インデント、Blade 判定が正常です。")
