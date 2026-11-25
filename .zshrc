# 分割された設定ファイルを読み込む
source ~/.zsh/env.zsh         # 環境変数の設定
source ~/.zsh/history.zsh     # 履歴設定
source ~/.zsh/keybindings.zsh # キーバインディング設定
source ~/.zsh/functions.zsh   # 関数定義
source ~/.zsh/aliases.zsh     # エイリアス定義

# starshipの呼び出し
eval "$(starship init zsh)"
# コマンドの検索先は env.zsh で設定済みのため、ここでは追加しない。
alias gh='command gh'
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/ishiooon/.docker/completions $fpath)
autoload -Uz compinit
(( ${+_comps[docker]} )) || compinit
# End of Docker CLI completions

# Docker Desktopのコマンドを対話型ターミナルから利用できるようにします。
case ":$PATH:" in
  *":$HOME/.docker/bin:"*) ;;
  *) export PATH="$HOME/.docker/bin:$PATH" ;;
esac

# 開発コンテナと同じPHP 8.3を使用し、コミット前の整形ツールとの互換性を保ちます。
case ":$PATH:" in
  *":/opt/homebrew/opt/php@8.3/bin:"*) ;;
  *) export PATH="/opt/homebrew/opt/php@8.3/bin:$PATH" ;;
esac

# bun の補完。未インストールなら何もしない。
if [[ -n "${BUN_INSTALL:-}" && -s "$BUN_INSTALL/_bun" ]]; then
  source "$BUN_INSTALL/_bun"
fi
