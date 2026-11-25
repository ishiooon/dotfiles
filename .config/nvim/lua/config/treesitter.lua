local M = {}
local requested = {}
local tasks = {}
local required_languages

-- パーサーの保存先とファイル種別を設定し、読み込み済みのバッファにも設定を反映する。
function M.setup(opts)
    require("nvim-treesitter").setup({})
    required_languages = vim.deepcopy(opts.ensure_installed or {})
    vim.filetype.add({ pattern = { [".*%.blade%.php"] = "blade" } })
    local group = vim.api.nvim_create_augroup("DotfilesTreesitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(event) M.enable_buffer(event.buf) end,
        desc = "対応するファイルの色分けとインデントを有効にする",
    })
    M.install_parsers(required_languages)
    M.refresh_buffers()
end

-- 初期設定で開始した処理の完了を待ち、取得失敗や必要なパーサーの不足を呼び出し元へ伝える。
function M.wait_for_parsers(timeout)
    assert(required_languages, "Treesitter の初期設定が実行されていません。")
    local deadline = vim.uv.hrtime() / 1000000 + (timeout or 300000)
    for _, task in ipairs(tasks) do
        local remaining = math.max(0, math.floor(deadline - vim.uv.hrtime() / 1000000))
        assert(task:wait(remaining), "Treesitter のパーサーを取得できませんでした。")
    end
    local installed = require("nvim-treesitter").get_installed("parsers")
    for _, language in ipairs(required_languages) do
        assert(vim.list_contains(installed, language), "Treesitter のパーサーが未導入です: " .. language)
    end
end

-- 非同期のパーサー導入後も、既に開いている全バッファで色分けを開始する。
function M.refresh_buffers()
    for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buffer) then M.enable_buffer(buffer) end
    end
end

-- 通常のファイルで色分けを開始し、未導入の対応言語は非同期で取得する。
function M.enable_buffer(buffer)
    if not vim.api.nvim_buf_is_valid(buffer) or vim.bo[buffer].buftype ~= "" then return end
    local filetype = vim.bo[buffer].filetype
    local language = vim.treesitter.language.get_lang(filetype)
    if not language then return end
    if not pcall(vim.treesitter.start, buffer, language) then
        if require("nvim-treesitter.parsers")[language] then M.install_parsers({ language }) end
        return
    end

    -- Ruby のインデントと Markdown の表示に必要な、従来の正規表現による色分けも残す。
    if filetype == "ruby" or filetype == "markdown" then vim.bo[buffer].syntax = filetype end
    if language ~= "ruby" and vim.treesitter.query.get(language, "indents") then
        vim.bo[buffer].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
end

-- 同じ言語の取得を一度にまとめ、失敗時にファイルを開くたびに再取得し続けることを防ぐ。
function M.install_parsers(languages)
    local pending = {}
    for _, language in ipairs(languages) do
        if not requested[language] then
            requested[language] = true
            table.insert(pending, language)
        end
    end
    if #pending == 0 then return end
    local task = require("nvim-treesitter").install(pending)
    table.insert(tasks, task)
    task:await(vim.schedule_wrap(function(err, success)
        if not err and success then M.refresh_buffers() end
    end))
end

return M
