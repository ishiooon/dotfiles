# 対話的でない場合は何もしない
case $- in
    *i*) ;;
      *) return;;
esac

# 分割された設定ファイルを読み込む
source ~/.bash/env.bash        # 環境変数の設定
source ~/.bash/history.bash    # 履歴関連の設定
source ~/.bash/terminal.bash   # ターミナル関連の設定
source ~/.bash/aliases.bash    # エイリアス定義
source ~/.bash/completion.bash # 補完機能の設定
source ~/.bash/functions.bash  # 関数定義
source ~/.bash/starship.bash   # starshipの設定

# 追加のエイリアス定義があれば~/.bash_aliasesを読み込む
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
alias gh="/usr/local/bin/gh"
