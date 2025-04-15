# ターミナル関連の設定

# 各コマンドの後にウィンドウサイズを確認し、必要に応じてLINESとCOLUMNSの値を更新する
shopt -s checkwinsize

# lessを非テキスト入力ファイルに対してよりフレンドリーにする
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# 作業中のchrootを識別する変数を設定する
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# 派手なプロンプトを設定(非カラー、カラーを“望む”場合を除く)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# カラー付きプロンプトを有効にする設定
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	color_prompt=yes
    else
	color_prompt=
    fi
fi

# プロンプトの設定
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# xtermの場合のタイトル設定
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac
