#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_FILE="$ROOT_DIR/.zsh/functions/fzf_history.zsh"
HISTORY_LIST_SCRIPT="$ROOT_DIR/.zsh/scripts/list_history_entries.sh"

# 検証対象が存在しない場合は即時失敗し、設定漏れを検知する。
if [[ ! -f "$TARGET_FILE" ]]; then
  echo "検証対象が見つかりません: $TARGET_FILE" >&2
  exit 1
fi

# zsh 関数を直接読み込み、fzf の出力解釈だけを振る舞いとして検証する。
TARGET_FILE="$TARGET_FILE" zsh <<'EOF'
source "$TARGET_FILE"

# 期待値と実際の値を比較し、差異があれば即時失敗する。
assert_equal() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" != "$actual" ]]; then
    print -u2 -- "$message"
    print -u2 -- "期待値: $expected"
    print -u2 -- "実際値: $actual"
    exit 1
  fi
}

# 既定の Enter は空行として返るため、選択済みコマンドがある場合だけ Enter と解釈する。
enter_output=$'\necho selected'
enter_command="$(hf_extract_selected_command "$enter_output")"
enter_key="$(hf_normalize_pressed_key "$(hf_extract_pressed_key "$enter_output")" "$enter_command")"
assert_equal "echo selected" "$enter_command" "Enter 時の選択コマンド解釈に失敗しました。"
assert_equal "enter" "$enter_key" "Enter 時の押下キー解釈に失敗しました。"

# Tab は明示的なキー名が返るため、そのまま維持されることを確認する。
tab_output=$'tab\necho reuse'
tab_command="$(hf_extract_selected_command "$tab_output")"
tab_key="$(hf_normalize_pressed_key "$(hf_extract_pressed_key "$tab_output")" "$tab_command")"
assert_equal "echo reuse" "$tab_command" "Tab 時の選択コマンド解釈に失敗しました。"
assert_equal "tab" "$tab_key" "Tab 時の押下キー解釈に失敗しました。"

# キャンセル時の空出力は Enter と誤認せず、そのまま空として扱う。
empty_output=''
empty_command="$(hf_extract_selected_command "$empty_output")"
empty_key="$(hf_normalize_pressed_key "$(hf_extract_pressed_key "$empty_output")" "$empty_command")"
assert_equal "" "$empty_command" "空出力時の選択コマンド解釈に失敗しました。"
assert_equal "" "$empty_key" "空出力時の押下キー解釈に失敗しました。"

print -r -- "PASS: hf の fzf 出力解釈は Enter と Tab を正しく扱えました。"
EOF

# hf が選択値を永続化し、新しい zsh からも履歴として復元できることを検証する。
TEMP_HOME="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_HOME"
}
trap cleanup EXIT
mkdir -p "$TEMP_HOME/.zsh/scripts"
cp "$HISTORY_LIST_SCRIPT" "$TEMP_HOME/.zsh/scripts/list_history_entries.sh"

TARGET_FILE="$TARGET_FILE" HOME="$TEMP_HOME" zsh -f -i 2>/dev/null <<'EOF'
PROMPT=''
HISTFILE="$HOME/.zsh_history"
SAVEHIST=100
source "$TARGET_FILE"

# fzf の選択操作を再現し、履歴へ追加する入力値を hf 本体へ返す。
fzf() {
  cat >/dev/null
  print -r -- $'enter\ntrue hf-persisted-input'
}

hf >/dev/null
EOF

# 別プロセスの zsh で履歴ファイルを読み込み、再起動後の復元可能性を確認する。
RESTORED_HISTORY="$(HOME="$TEMP_HOME" zsh -f <<'EOF'
HISTFILE="$HOME/.zsh_history"
fc -R "$HISTFILE"
print -rl -- "${(v)history}"
EOF
)"

if [[ "$RESTORED_HISTORY" != *"true hf-persisted-input"* ]]; then
  echo "hf の入力値を新しい zsh から履歴として復元できませんでした。" >&2
  exit 1
fi

echo "PASS: hf の入力値は履歴ファイルへ永続化され、新しい zsh から復元できました。"
