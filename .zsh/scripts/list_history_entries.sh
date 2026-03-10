#!/bin/zsh

# hf で表示する履歴一覧を生成するスクリプト。
# zsh 履歴のタイムスタンプ形式と通常形式の両方を扱い、
# 表示不要な設定行を除外したうえで重複を取り除き、新しい順へ並び替える。

# 履歴から除外する設定系コマンドのパターン。
HISTORY_FILTER_PATTERN='^(HISTFILE=|HISTCONTROL=|shopt -s histappend|HISTSIZE=|HISTFILESIZE=|PROMPT_COMMAND="history -a|SAVEHIST=|setopt|set -o history|#|HISTIGNORE=)'

# HISTFILE が未設定の場合は zsh の既定履歴ファイルを使う。
if [[ -z "$HISTFILE" ]]; then
  HISTFILE="$HOME/.zsh_history"
fi

# 入力行を逆順に並べる。
# tac が無い環境では tail -r、それも無い場合は awk で代替する。
reverse_lines() {
  if (( $+commands[tac] )); then
    tac
    return
  fi

  if tail -r /dev/null >/dev/null 2>&1; then
    tail -r
    return
  fi

  awk '
    { lines[NR] = $0 }
    END {
      for (index = NR; index >= 1; index--) {
        print lines[index]
      }
    }
  '
}

# 履歴ファイルを読み込み、拡張履歴形式のプレフィックスを取り除く。
load_history_lines() {
  if [[ ! -f "$HISTFILE" ]]; then
    return 0
  fi

  cut -d';' -f2- "$HISTFILE"
}

# 履歴として表示しない行を除外する。
filter_history_lines() {
  grep -a -vE "$HISTORY_FILTER_PATTERN" || true
}

# 重複行を先勝ちで一意化する。
deduplicate_lines() {
  awk '!seen[$0]++'
}

main() {
  load_history_lines | filter_history_lines | deduplicate_lines | reverse_lines
}

main "$@"
