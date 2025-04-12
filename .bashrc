# ~/.bashrc: bash(1)によって非ログインシェルで実行されます。
# 例については、/usr/share/doc/bash/examples/startup-files (bash-docパッケージ内)を参照してください。

# 対話的でない場合は何もしない
case $- in
    *i*) ;;
      *) return;;
esac

# 履歴に重複行やスペースで始まる行を入れない。
# 詳細はbash(1)を参照してください。
HISTCONTROL=ignoreboth

# 履歴ファイルに追加し、上書きしない
shopt -s histappend

# 履歴の長さを設定するには、bash(1)のHISTSIZEとHISTFILESIZEを参照してください。
HISTSIZE=10000
HISTFILESIZE=20000

# 各コマンドの後にウィンドウサイズを確認し、必要に応じてLINESとCOLUMNSの値を更新します。
shopt -s checkwinsize

# 設定されている場合、パス名展開コンテキストで使用されるパターン"**"は、すべてのファイルと0個以上のディレクトリおよびサブディレクトリに一致します。
#shopt -s globstar

# lessを非テキスト入力ファイルに対してよりフレンドリーにする。詳細はlesspipe(1)を参照してください。
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# 作業中のchrootを識別する変数を設定します（以下のプロンプトで使用されます）。
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# 派手なプロンプトを設定します（非カラー、カラーを"望む"場合を除く）。
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# カラー付きプロンプトを有効にするには、ターミナルがその機能を持っている場合にコメントを外します。デフォルトではオフになっています。
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# カラーサポートがあります。Ecma-48 (ISO/IEC-6429)に準拠していると仮定します。
	# そのようなサポートがない場合は非常にまれで、その場合はsetfよりもsetafをサポートする傾向があります。
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# これがxtermの場合、タイトルをuser@host:dirに設定します。
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# lsのカラーサポートを有効にし、便利なエイリアスを追加します。
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# GCCの警告とエラーをカラー表示
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# いくつかのlsエイリアス
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# 長時間実行されるコマンドのための"alert"エイリアスを追加します。以下のように使用します。
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# エイリアスの定義。
# すべての追加をここに直接追加するのではなく、~/.bash_aliasesのような別のファイルに入れることをお勧めします。
# bash-docパッケージの/usr/share/doc/bash-doc/examplesを参照してください。

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# プログラム可能な補完機能を有効にします（/etc/bash.bashrcと/etc/profileが/etc/bash.bashrcをソースとしている場合は有効にする必要はありません）。
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
eval "$(starship init bash)"

# hf - fzfを使って履歴をインタラクティブに検索する
# 直近の履歴が上に表示され、重複コマンドは排除される
# Enterで実行、Tabでコマンドラインに挿入、Ctrl-dで履歴から削除
hf() {
  local selected
  local cmd
  local key
  
  # ログメッセージを表示
  echo ""
  echo "\033[1;34m●\033[0m \033[1;36mコマンド履歴検索\033[0m"
  echo "\033[90m直近のコマンド履歴から検索します..\033[0m"
  
  # 除外リストファイルが存在しない場合は作成
  if [[ ! -f ~/.bash_history_exclude ]]; then
    touch ~/.bash_history_exclude
  fi
  
  # コマンド履歴をファイルに書き出し
  local history_file=$(mktemp)
  # historyコマンドを使用して重複を除去（直近のコマンドが上に来るように処理）
  # 除外リストにあるコマンドは表示しない
  history | awk '{$1=""; print substr($0, 2)}' | awk '!seen[$0]++' | grep -v -f ~/.bash_history_exclude > "$history_file"
  
  # fzfでコマンドを選択
  selected=$(cat "$history_file" | fzf \
    --layout=reverse \
    --border=rounded \
    --prompt="🔍 " \
    --pointer="▶" \
    --marker="✓" \
    --header="ENTER: 実行 | TAB: コマンドラインに挿入 | delete: 履歴から削除" \
    --header-first \
    --color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#88C0D0,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#A3BE8C,fg+:#D8DEE9,prompt:#81A1C1,hl+:#88C0D0 \
    --bind "delete:execute(grep -Fxv {}"' "$history_file" > "${history_file}.tmp" && mv "${history_file}.tmp" "$history_file" && echo {} >> ~/.bash_history_exclude && history -w && grep -v -f ~/.bash_history_exclude ~/.bash_history > ~/.bash_history.tmp && mv ~/.bash_history.tmp ~/.bash_history && history -r && echo "# 履歴アイテムを削除しました: {}")+reload(cat "$history_file")"' \
    --expect=tab,enter)
  
  # 最初の行はキー、2行目が選択されたコマンド
  key=$(head -1 <<< "$selected")
  cmd=$(tail -n +2 <<< "$selected" | sed 's/^[[:space:]]//')
  
  # 一時ファイルを削除
  rm "$history_file" 2>/dev/null
  rm "${history_file}.tmp" 2>/dev/null
  
  # キーに応じた処理
  if [[ $key == "tab" && -n "$cmd" ]]; then
    # コマンドラインに挿入（Bashでは少し異なる方法を使用）
    history -s "$cmd"
    echo -e "\033[1;36mコマンドラインに挿入しました\033[0m ➜ \033[1;33m$cmd\033[0m"
    bind '"\C-x\C-e": "\e0\C-k'"$cmd"'\C-m"'
    printf "\C-x\C-e"
    bind -x '"\C-x\C-e": ""'
  elif [[ -n "$cmd" ]]; then
    # 直接実行
    echo ""
    echo "\033[1;36m実行するコマンド \033[0m➜ \033[1;33m$cmd\033[0m"
    echo ""
    # コマンドを履歴に追加
    history -s "$cmd"
    # コマンドを実行
    eval "$cmd"
  fi
}

