# 履歴管理に関連する関数

# 履歴から特定のコマンドを削除する関数
delete_from_history() {
  local cmd="$1"
  # zsh履歴ファイルから特定のコマンドを削除
  awk -v cmd="$cmd" '!index($0, cmd)' ~/.zsh_history > ~/.zsh_history.tmp
  mv ~/.zsh_history.tmp ~/.zsh_history
  # 履歴を再読み込み
  fc -R ~/.zsh_history
}

