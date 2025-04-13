# fzfを使った履歴検索関数

# hf - fzfを使って履歴をインタラクティブに検索する関数
hf() {
  local selected
  local cmd
  local key
  
  # ログメッセージを表示
  echo "\033[1;34m●\033[0m \033[1;36m-fzf\033[0m"
  
  # コマンド履歴をファイルに書き出し
  local history_file=$(mktemp)
  # historyコマンドを使用して重複を除去
  fc -l 1 | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' > "$history_file"
  
  # fzfでコマンドを選択（初期表示は最近のコマンド=全表示）
  selected=$(cat "$history_file" | fzf \
    --layout=reverse \
    --border=rounded \
    --prompt="🔍 " \
    --pointer="▶" \
    --marker="✓" \
    --header="履歴 | ENTER: 実行 | TAB: コマンドラインに挿入 | CTRL-D: 履歴から削除" \
    --header-first \
    --query="" \
    --color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#88C0D0,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#A3BE8C,fg+:#D8DEE9,prompt:#81A1C1,hl+:#88C0D0 \
    --bind "ctrl-d:execute-silent(echo {} | xargs -I CMD zsh -c 'source ~/.zshrc && delete_from_history \"CMD\"')+execute-silent(echo '\033[1;31m履歴から削除: {}\033[0m' >&2)+reload(cat \"$history_file\" | grep -v {})" \
    --expect=tab,enter)
  
  # 最初の行はキー、2行目が選択されたコマンド
  key=$(head -1 <<< "$selected")
  cmd=$(tail -n +2 <<< "$selected" | sed 's/^[[:space:]]//')
  
  # 一時ファイルを削除
  rm "$history_file" 2>/dev/null
  
  # キーに応じた処理
  if [[ $key == "tab" && -n "$cmd" ]]; then
    # コマンドラインに挿入
    print -z "$cmd"
  elif [[ -n "$cmd" ]]; then
    # 直接実行
    echo ""
    echo "\033[1;36mExec \033[0m➜ \033[1;33m$cmd\033[0m"
    echo ""
    # コマンドを履歴に追加
    print -s "$cmd"
    # コマンドを実行
    eval "$cmd"
    # コマンドをコマンドラインに表示
    print -z "$cmd"
  fi
}

