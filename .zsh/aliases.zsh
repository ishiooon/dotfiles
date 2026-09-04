# zsh aliases

# macOS の標準コマンドと GNU 系コマンドの差を吸収し、どちらでも色付き表示を使えるようにする。
if [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

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