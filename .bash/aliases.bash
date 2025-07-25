# lsのカラーサポートを有効にし、便利なエイリアスを追加
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# いくつかのlsエイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# 長時間実行されるコマンドのための"alert"エイリアス
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# 履歴をクリーンアップするエイリアス
alias clean-history='~/.bin/clean_history.sh'

# GitHub CLI
alias gh='~/.local/bin/github-cli'

# Claude Code with character.md management
alias claude-code='~/.bin/claude-code-wrapper'
