# 分割された設定ファイルを読み込む
source ~/.zsh/env.zsh         # 環境変数の設定
source ~/.zsh/history.zsh     # 履歴設定
source ~/.zsh/keybindings.zsh # キーバインディング設定
source ~/.zsh/functions.zsh   # 関数定義

# starshipの呼び出し
eval "$(starship init zsh)"



export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
