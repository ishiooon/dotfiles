# 履歴関連の設定

# bash履歴機能を有効にする
set -o history

# 履歴ファイルの場所を指定
HISTFILE=~/.bash_history

# 履歴に重複行やスペースで始まる行を入れない
HISTCONTROL=ignoreboth

# 履歴ファイルに追加し、上書きしない
shopt -s histappend

# 履歴の長さの設定
HISTSIZE=10000
HISTFILESIZE=20000

# 各コマンド実行後に履歴をファイルに保存
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
