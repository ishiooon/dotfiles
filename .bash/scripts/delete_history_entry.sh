#!/bin/bash

# 履歴から特定のコマンドを削除するスクリプト
# 使用方法: delete_history_entry.sh "削除したいコマンド"

command_to_delete="$1"

if [[ -z "$command_to_delete" ]]; then
  echo "削除するコマンドが指定されていません" >&2
  exit 1
fi

# HISTFILEが設定されていない場合はデフォルトを使用
if [[ -z "$HISTFILE" ]]; then
  HISTFILE="$HOME/.bash_history"
fi

# BASHの履歴ファイルから該当コマンドを削除
if [[ -f "$HISTFILE" ]]; then
  # 一時ファイルを作成
  temp_file=$(mktemp)
  
  # 該当コマンドを除外してファイルを書き直す
  grep -F -v "$command_to_delete" "$HISTFILE" > "$temp_file"
  
  # 元のファイルを上書き
  mv "$temp_file" "$HISTFILE"
  
  echo "履歴から削除しました: $command_to_delete" >&2
else
  echo "履歴ファイルが見つかりません: $HISTFILE" >&2
  exit 1
fi
