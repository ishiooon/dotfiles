-- 開発版の候補と、見つからない場合に使う公開版を共通の判定で選択する。
return {
  require("config.plugin_source").resolve("ishiooon/idle-dungeon.nvim", {
    "/home/dev_local/dev_plugin/idle-dungeon.nvim",
  }, {
    config = function()
      -- 既定設定で初期化し、ゲーム用のコマンドやイベントを登録する。
      require("idle_dungeon").setup({})
    end,
  }),
}
