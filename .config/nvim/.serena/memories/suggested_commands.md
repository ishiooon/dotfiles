# 開発・運用で使うコマンド
- `nvim .` : 設定全体を開いて編集。
- `:Lazy sync` / `:Lazy update` / `:Lazy check` : lazy.nvim 経由でプラグインの同期・更新・チェック。
- `:checkhealth` : Neovim/各プラグインのヘルスチェック。
- `:source %` : 編集中の設定 Lua ファイルを即時リロード。
- (必要に応じて) `:Mason` / `:MasonUpdate` : LSP/ツールのインストールや更新。
- Codex 関連で外部プロセスが必要な場合、`<leader>cr` (もしくは `npx --yes @nogataka/ccresume-codex@latest`) で起動。