# fzfを使った履歴検索関数
# 使い方: hf を入力して実行するとインタラクティブな履歴検索が開始される

# hf - fzfを使って履歴をインタラクティブに検索する関数
hf() {
  local selected_output   # fzfの出力結果（キーと選択されたコマンドを含む）
  local selected_command  # ユーザーが選択したコマンド
  local pressed_key       # ユーザーが押したキー
  
  # fzf起動を示すログメッセージを表示
  echo -e "\033[1;34m●\033[0m \033[1;36m-fzf\033[0m"
  
  # フィルタリング関数を定義
  filter_history() {
    grep -a -vE '^(HISTFILE=|HISTCONTROL=|shopt -s histappend|HISTSIZE=|HISTFILESIZE=|PROMPT_COMMAND="history -a|SAVEHIST=|setopt|set -o history|#|HISTIGNORE=)'
  }
  
  # fzfを使ってコマンドを選択するUI設定
  # --layout=reverse: リストを下から上に表示
  # --expect=tab,enter: TABとENTERキーの押下を検知
  # fzfのbind内では正規表現の丸括弧が誤解釈される環境があるため、行頭アンカーを並べる形式で除外条件を記述する
  selected_output=$(cat ~/.zsh_history | cut -d';' -f2- | filter_history | awk '!seen[$0]++' | tac | fzf \
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
    --bind "ctrl-r:execute-silent(echo -e '\033[1;32m履歴を更新しました\033[0m' >&2)+reload(cat ~/.zsh_history | cut -d';' -f2- | grep -a -vE '^HISTFILE=|^HISTCONTROL=|^shopt -s histappend|^HISTSIZE=|^HISTFILESIZE=|^PROMPT_COMMAND=\"history -a|^SAVEHIST=|^setopt|^set -o history|^#|^HISTIGNORE=' | awk '!seen[\$0]++' | tac)" \
    --expect=tab,enter)
  
  # fzfの出力から押されたキーと選択されたコマンドを取得
  # 最初の行が押されたキー、2行目以降が選択されたコマンド
  pressed_key=$(head -1 <<< "$selected_output")
  selected_command=$(tail -n +2 <<< "$selected_output" | sed 's/^[[:space:]]//') 
  
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
