# fzfを使った履歴検索関数
# 使い方: hf を入力して実行するとインタラクティブな履歴検索が開始される

# hf - fzfを使って履歴をインタラクティブに検索する関数
hf() {
  local selected_output   # fzfの出力結果（キーと選択されたコマンドを含む）
  local selected_command  # ユーザーが選択したコマンド
  local pressed_key       # ユーザーが押したキー
  local history_list_script="$HOME/.zsh/scripts/list_history_entries.sh" # 履歴一覧を生成する共通スクリプト
  
  # fzf起動を示すログメッセージを表示
  echo -e "\033[1;34m●\033[0m \033[1;36m-fzf\033[0m"

  # fzfを使ってコマンドを選択するUI設定
  # --layout=reverse: リストを下から上に表示
  # --expect=tab,enter: TABとENTERキーの押下を検知
  # macOSの既定環境にはtacが無いため、履歴整形は共通スクリプト側で移植性を吸収する。
  selected_output=$("$history_list_script" | fzf \
    --layout=reverse \
    --border=rounded \
    --prompt="🔍 " \
    --pointer="▶" \
    --marker="✓" \
    --header="履歴 | ENTER: 実行 | TAB: コマンドラインに挿入 | CTRL-D: 履歴から削除 | CTRL-R: 履歴更新" \
    --header-first \
    --query="" \
    --color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#88C0D0,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#A3BE8C,fg+:#D8DEE9,prompt:#81A1C1,hl+:#88C0D0 \
    --bind "ctrl-d:reload(~/.zsh/scripts/delete_history_entry.sh {})" \
    --bind "ctrl-r:execute-silent(echo -e '\033[1;32m履歴を更新しました\033[0m' >&2)+reload(${history_list_script})" \
    --expect=tab,enter)
  
  # fzfの出力から押されたキーと選択されたコマンドを取得
  # fzfは既定のEnter時にキー名ではなく空行を返すため、補助関数で仕様差を吸収する。
  pressed_key=$(hf_extract_pressed_key "$selected_output")
  selected_command=$(hf_extract_selected_command "$selected_output")
  pressed_key=$(hf_normalize_pressed_key "$pressed_key" "$selected_command")
  
  # 何か選択されていた場合のみ処理を実行
  if [[ -n "$selected_command" ]]; then
    # 押されたキーに応じた処理を実行
    if [[ "$pressed_key" == "tab" ]]; then
      # TABキーの場合: コマンドをコマンドラインに挿入するだけ（実行はしない）
      echo -e "\033[1;36mInsert \033[0m➡ \033[1;33m$selected_command\033[0m"
      # コマンドを履歴に追加
      print -s "$selected_command"
      # コマンドをコマンドラインに挿入
      print -z "$selected_command"
    elif [[ "$pressed_key" == "enter" ]]; then
      # ENTERキーの場合: コマンドを実行する
      echo -e "\033[1;36mExec \033[0m➡ \033[1;33m$selected_command\033[0m"
      # コマンドを履歴に追加
      print -s "$selected_command"
      # コマンドを実行
      eval "$selected_command"
    fi
  fi
}

# fzfの出力先頭行から、押下されたキー名を取り出す。
hf_extract_pressed_key() {
  head -1 <<< "$1"
}

# fzfの2行目以降から、実行や挿入の対象になるコマンドを取り出す。
hf_extract_selected_command() {
  tail -n +2 <<< "$1" | sed 's/^[[:space:]]//'
}

# 既定のEnterは空行で返るため、選択済みコマンドがある場合だけEnterとして正規化する。
hf_normalize_pressed_key() {
  local pressed_key="$1"
  local selected_command="$2"

  if [[ -z "$pressed_key" && -n "$selected_command" ]]; then
    print -r -- "enter"
    return 0
  fi

  print -r -- "$pressed_key"
}
