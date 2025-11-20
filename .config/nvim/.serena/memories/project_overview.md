# プロジェクト概要
- 目的: Neovim の個人設定 (Lua)。lazy.nvim でプラグインを管理し、キーマップや補助関数を整備する dotfiles。
- 主構成: `init.lua` から `config.lazy` を読み込み、`lua/config/lazy.lua` が lazy.nvim をブートストラップ (リーダーキー `;`)。共通設定は `lua/config/`、プラグイン個別設定は `lua/plugins/` 配下で管理。
- Codex 周り: `lua/plugins/codex.lua` でウィンドウ配置・ショートカットを調整し、`lua/config/keymaps_codex.lua` で Codex 用キーマップをまとめている。
- 補足: `tests` 配下などの自動テストは見当たらず、`neovim_tips` やメモ類が補助資料として置かれている。