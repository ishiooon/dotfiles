#!/bin/zsh

# 履歴から特定のコマンドを削除するスクリプト
# 使用方法: delete_history_entry.sh "削除したいコマンド"

command_to_delete="$1"

if [[ -z "$command_to_delete" ]]; then
  echo "削除するコマンドが指定されていません" >&2
  exit 1
fi

# HISTFILEが設定されていない場合はデフォルトを使用
if [[ -z "$HISTFILE" ]]; then
  HISTFILE="$HOME/.zsh_history"
fi

# ZSHの履歴ファイルから該当コマンドを削除
if [[ -f "$HISTFILE" ]]; then
  # 一時ファイルを作成
  temp_file=$(mktemp)
  
  # zsh履歴はタイムスタンプ付きの形式なので、コマンド部分のみでマッチング
  # 該当コマンドを除外してファイルを書き直す
  while IFS= read -r line; do
    # zsh履歴の形式: ": timestamp:0;command"
    if [[ "$line" =~ ^:[[:digit:]]+:[[:digit:]]+\;(.*)$ ]]; then
      cmd_part="${match[1]}"
      if [[ "$cmd_part" != "$command_to_delete" ]]; then
        echo "$line" >> "$temp_file"
      fi
    else
      # タイムスタンプなしの形式の場合
      if [[ "$line" != "$command_to_delete" ]]; then
        echo "$line" >> "$temp_file"
      fi
    fi
  done < "$HISTFILE"
  
  # 元のファイルを上書き
  mv "$temp_file" "$HISTFILE"
  
  # ファイルシステムの同期を保証（fzfのreloadタイミング調整）
  sync
  sleep 0.5
  
  echo "履歴から削除しました: $command_to_delete" >&2
  
  # 削除後の履歴リストを出力（fzfのreload用）
  cat "$HISTFILE" | cut -d';' -f2- | awk '!seen[$0]++' | tac
else
  echo "履歴ファイルが見つかりません: $HISTFILE" >&2
  exit 1
fi