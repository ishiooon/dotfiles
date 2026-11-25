-- 候補ディレクトリの存在だけをメモリー上で切り替え、実際のファイルは変更しない。
local entries = {}
vim.uv.fs_stat = function(path) return entries[path] end
package.path = vim.env.ROOT_DIR .. "/.config/nvim/lua/?.lua;" .. package.path
local cases = {
    { name = "box-breathing", paths = { vim.fn.expand("~/develop/nvim_plugins/box-breathing.nvim") } },
    { name = "random-chord", paths = { vim.fn.expand("~/develop/nvim_plugins/random-chord.nvim") } },
    { name = "codex", paths = { "/Users/ishiooon/develop/nvim_plugins/codex.nvim", "/home/dev_local/dev_plugin/codex.nvim" } },
    { name = "idle-dungeon", paths = { "/home/dev_local/dev_plugin/idle-dungeon.nvim" } },
}

-- プラグイン設定を読み直し、候補が無い環境と開発版がある環境の両方を検証する。
local function read_spec(name)
    return dofile(vim.env.ROOT_DIR .. "/.config/nvim/lua/plugins/" .. name .. ".lua")[1]
end

-- 移行前の Mac の配置だけが残っていても、古い開発版を誤って読み込まない。
entries = {
    ["/Users/ishiooon/develop/codex.nvim"] = { type = "directory" },
    [vim.fn.expand("~/dev_plugin/box-breathing.nvim")] = { type = "directory" },
    [vim.fn.expand("~/dev_plugin/random-chord.nvim")] = { type = "directory" },
}
for _, name in ipairs({ "codex", "box-breathing", "random-chord" }) do
    assert(read_spec(name).dir == nil, "移行前の配置を参照しています: " .. name)
end

for _, case in ipairs(cases) do
    entries = {}
    local remote = read_spec(case.name)
    assert(remote[1] == "ishiooon/" .. case.name .. ".nvim", "公開版の参照先が不正です: " .. case.name)
    assert(remote.dir == nil, "存在しない開発用ディレクトリを参照しています: " .. case.name)
    for index, directory in ipairs(case.paths) do
        entries = {}
        -- 先行候補に同名ファイルがあっても、後続の有効なディレクトリを選択する。
        for previous = 1, index - 1 do entries[case.paths[previous]] = { type = "file" } end
        entries[directory] = { type = "directory" }
        local local_spec = read_spec(case.name)
        assert(local_spec.dir == directory, "開発版の候補を選択できません: " .. case.name)
        assert(local_spec[1] == nil, "開発版と公開版を同時に指定しています: " .. case.name)
        assert(local_spec.name == remote.name, "開発版と公開版でプラグイン名が変わっています: " .. case.name)
    end
end

-- 呼吸ガイドの既存の速度設定と、Codex の初期化・WezTerm 連携を維持する。
entries = {}
local breathing = read_spec("box-breathing")
assert(breathing.opts.duration == 4 and breathing.opts.animation_interval == 50, "呼吸ガイドの設定が変わっています。")
local calls = {}
package.loaded.codex = { setup = function() calls.codex = true end }
package.loaded["config.codex_wezterm"] = { setup = function() calls.wezterm = true end }
read_spec("codex").config()
assert(calls.codex and calls.wezterm, "Codex の初期化または WezTerm 連携が呼ばれません。")
package.loaded.idle_dungeon = { setup = function(options) calls.idle_dungeon = options end }
read_spec("idle-dungeon").config()
assert(type(calls.idle_dungeon) == "table", "Idle Dungeon の初期化が呼ばれません。")

-- 複数の開発版がある場合は、設定に記載した順序で候補を選択する。
for _, directory in ipairs(cases[3].paths) do entries[directory] = { type = "directory" } end
assert(read_spec("codex").dir == cases[3].paths[1], "開発版候補の優先順位が変わっています。")
print("PASS: 開発版の選択、公開版への切り替え、既存プラグインの初期化が正常です。")
