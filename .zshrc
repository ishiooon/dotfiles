# コマンド履歴を１万行保存する
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups  # 同じコマンドを履歴に残さない
setopt share_history     # 同時に起動したzshで履歴を共有する

# Ctrl + N/Pでコマンド履歴を検索する
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^N" history-beginning-search-forward-end
bindkey "^P" history-beginning-search-backward-end

# starshipの呼び出し
eval "$(starship init zsh)"

# 関数定義
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
  if [[ ! -f ~/.zsh_history_exclude ]]; then
    touch ~/.zsh_history_exclude
  fi
  
  # コマンド履歴をファイルに書き出し
  local history_file=$(mktemp)
  # historyコマンドを使用して重複を除去（直近のコマンドが上に来るように処理）
  # 除外リストにあるコマンドは表示しない
  fc -l 1 | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' | grep -v -f ~/.zsh_history_exclude > "$history_file"
  
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
    --bind "delete:execute(grep -Fxv {}"' "$history_file" > "${history_file}.tmp" && mv "${history_file}.tmp" "$history_file" && echo {} >> ~/.zsh_history_exclude && fc -W && grep -v -f ~/.zsh_history_exclude ~/.zsh_history > ~/.zsh_history.tmp && mv ~/.zsh_history.tmp ~/.zsh_history && fc -R && print -s "# 履歴アイテムを削除しました: {}")+reload(cat "$history_file")'" \
    --expect=tab,enter)
  
  # 最初の行はキー、2行目が選択されたコマンド
  key=$(head -1 <<< "$selected")
  cmd=$(tail -n +2 <<< "$selected" | sed 's/^[[:space:]]//')
  
  # 一時ファイルを削除
  rm "$history_file" 2>/dev/null
  rm "${history_file}.tmp" 2>/dev/null
  
  # キーに応じた処理
  if [[ $key == "tab" && -n "$cmd" ]]; then
    # コマンドラインに挿入
    print -z "$cmd"
  elif [[ -n "$cmd" ]]; then
    # 直接実行
    echo ""
    echo "\033[1;36m実行するコマンド \033[0m➜ \033[1;33m$cmd\033[0m"
    echo ""
    # コマンドを履歴に追加
    print -s "$cmd"
    # コマンドを実行
    eval "$cmd"
    # コマンドをコマンドラインに表示
    print -z "$cmd"
  fi
}











