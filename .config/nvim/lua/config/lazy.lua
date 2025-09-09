-- lazy.nvimのブートストラップ処理
-- プラグインマネージャーが存在しない場合は自動でインストール
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    -- GitHubからlazy.nvimをクローン
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    -- クローンに失敗した場合はエラーメッセージを表示して終了
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out, "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
-- ランタイムパスにlazy.nvimを追加
vim.opt.rtp:prepend(lazypath)

-- リーダーキーの設定
-- lazy.nvimを読み込む前に設定する必要がある
vim.g.mapleader = ";"

-- lazy.nvimのセットアップ
require("lazy").setup({
    spec = {
        -- pluginsディレクトリからプラグイン設定をインポート
        { import = "plugins" },
    },
    -- プラグインインストール時に使用するカラースキーム
    install = { colorscheme = { "habamax" } },
    -- プラグインの自動更新チェックを有効化
    checker = { enabled = true },
})

