# 履歴の設定
# コマンド履歴を１万行保存する
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups  # 同じコマンドを履歴に残さない
setopt share_history     # 同時に起動したzshで履歴を共有する

# 特定のパターンを履歴から除外する関数
function zshaddhistory() {
    local line="${1%%$'\n'}"
    # 設定コマンドやコメントを履歴に追加しない
    [[ "$line" =~ ^(HISTFILE=|HISTCONTROL=|shopt\ -s\ histappend|HISTSIZE=|HISTFILESIZE=|PROMPT_COMMAND=|SAVEHIST=|setopt|set\ -o\ history|#|HISTIGNORE=) ]] && return 1
    return 0
}

