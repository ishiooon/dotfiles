#!/bin/bash

# 履歴から特定のコマンドを削除する関数
delete_from_history() {
  local command_to_delete="$1"
  if [[ -z "$command_to_delete" ]]; then
    echo "削除するコマンドが指定されていません" >&2
    return 1
  fi
  
  # エスケープされた文字列を作成（sedで使用するため）
  local escaped_command=$(echo "$command_to_delete" | sed 's/[\/&]/\\&/g')
  
  # BASHの履歴ファイルから該当コマンドを削除
  if [[ -f "$HISTFILE" ]]; then
    # 一時ファイルを作成
    local temp_file=$(mktemp)
    # 該当コマンドを除外してファイルを書き直す
    sed "/^$escaped_command$/d" "$HISTFILE" > "$temp_file"
    # 元のファイルを上書き
    mv "$temp_file" "$HISTFILE"
    
    # 現在のセッションの履歴も更新
    history -r
    
    echo "履歴から削除しました: $command_to_delete" >&2
    return 0
  else
    echo "履歴ファイルが見つかりません" >&2
    return 1
  fi
}
# 履歴管理に関連する関数

# 履歴から特定のコマンドを削除する関数
delete_from_history() {
  local cmd="$1"
  # 履歴ファイルから特定のコマンドを含む行を削除
  if [ -f "$HISTFILE" ]; then
    awk -v cmd="$cmd" '!index($0, cmd)' "$HISTFILE" > "${HISTFILE}.tmp"
    mv "${HISTFILE}.tmp" "$HISTFILE"
    
    # 現在のセッションからも履歴を削除
    # history -cは内部メモリの履歴をクリアし、history -rはファイルから読み込み直す
    history -c
    history -r "$HISTFILE"
  fi
}
