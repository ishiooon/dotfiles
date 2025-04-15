# fzfを使った履歴検索関数
# 使い方: hf を入力して実行するとインタラクティブな履歴検索が開始される

# hf - fzfを使って履歴をインタラクティブに検索する関数
hf() {
  local selected_output   # fzfの出力結果（キーと選択されたコマンドを含む）
  local selected_command  # ユーザーが選択したコマンド
  local pressed_key       # ユーザーが押したキー
  
  # fzf起動を示すログメッセージを表示
  echo -e "\033[1;34m●\033[0m \033[1;36m-fzf\033[0m"
  
  # コマンド履歴を一時ファイルに書き出し
  local history_temp_file=$(mktemp)
  
  # 履歴を取得し、重複を除去して一時ファイルに保存
  # historyコマンドで全履歴を取得
  # 最初のawkで履歴番号を削除、2つ目のawkで重複を除去
  history | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' > "$history_temp_file"
  
  # 履歴の更新用関数を定義
  refresh_history_file() {
    history | awk '{$1=""; print substr($0,2)}' | awk '!seen[$0]++' > "$history_temp_file"
    cat "$history_temp_file"
  }

  # fzfを使ってコマンドを選択するUI設定
  # --layout=reverse: リストを下から上に表示
  # --expect=tab,enter: TABとENTERキーの押下を検知
  selected_output=$(refresh_history_file | fzf \
    --layout=reverse \
    --border=rounded \
    --prompt="🔍 " \
    --pointer="▶" \
    --marker="✓" \
    --header="履歴 | ENTER: 実行 | TAB: コマンドラインに挿入 | CTRL-D: 履歴から削除 | CTRL-R: 履歴更新" \
    --header-first \
    --query="" \
    --color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#88C0D0,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#A3BE8C,fg+:#D8DEE9,prompt:#81A1C1,hl+:#88C0D0 \
    --bind "ctrl-d:execute(source ~/.bash/functions/history_management.bash && delete_from_history {} > /dev/null 2>&1)+execute(echo -e '\033[1;31m履歴から削除: {}\033[0m' >&2)+reload(cat \"$history_temp_file\" | awk '!seen[$0]++')" \
    --bind "ctrl-r:execute(echo -e '\033[1;32m履歴を更新しました\033[0m' >&2)+reload(refresh_history_file)" \
    --expect=tab,enter)
  
  # fzfの出力から押されたキーと選択されたコマンドを取得
  # 最初の行が押されたキー、2行目以降が選択されたコマンド
  pressed_key=$(head -1 <<< "$selected_output")
  selected_command=$(tail -n +2 <<< "$selected_output" | sed 's/^[[:space:]]//') 
  
  # 一時ファイルを削除（エラー出力は無視）
  rm "$history_temp_file" 2>/dev/null
  
  # 押されたキーに応じた処理を実行
  if [[ $pressed_key == "tab" && -n "$selected_command" ]]; then
    # TABキーの場合: コマンドをコマンドラインに挿入するだけ（実行はしない）
    history -s "$selected_command"
    # コマンドを現在のコマンドラインに挿入
    READLINE_LINE="$selected_command"
    # カーソルを最後に配置
    READLINE_POINT=${#READLINE_LINE}
  elif [[ -n "$selected_command" ]]; then
    # ENTERキーの場合: コマンドを実行する
    echo -e "\033[1;36mExec \033[0m➡ \033[1;33m$selected_command\033[0m"
    # コマンドを履歴に追加
    history -s "$selected_command"
    # コマンドを実行
    eval "$selected_command"
  fi
}
