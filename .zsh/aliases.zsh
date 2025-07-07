# zsh aliases

# lsのカラーサポートを有効にし、便利なエイリアスを追加
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# いくつかのlsエイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# 履歴をクリーンアップするエイリアス
alias clean-history='~/.bin/clean_history.sh'

# GitHub CLI
alias gh='~/.local/bin/github-cli'

# Claude Code with character.md management
alias claude-code='~/.bin/claude-code-wrapper'