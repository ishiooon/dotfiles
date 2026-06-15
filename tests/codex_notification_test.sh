#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.codex/config.toml"
HOOKS_FILE="$ROOT_DIR/.codex/hooks.json"
NOTIFY_SCRIPT="$ROOT_DIR/.codex/scripts/codex_notify.sh"

if grep -Fq 'notify = ' "$CONFIG_FILE"; then
  echo "Codex の legacy notify が残っているため、subagent 完了でも通知音が鳴る可能性があります。" >&2
  exit 1
fi

if ! awk '/^\[tui\]/{inside_tui=1; next} /^\[/{inside_tui=0} inside_tui && /^notifications = \["approval-requested"\]$/{found=1} END{exit found ? 0 : 1}' "$CONFIG_FILE"; then
  echo "Codex の TUI 通知対象が、認証待ちだけに絞られていません。" >&2
  exit 1
fi

if ! awk '/^\[tui\]/{inside_tui=1; next} /^\[/{inside_tui=0} inside_tui && /^notification_method = "osc9"$/{found=1} END{exit found ? 0 : 1}' "$CONFIG_FILE"; then
  echo "Codex の認証待ち通知が、作業完了と同じ端末通知方式になっていません。" >&2
  exit 1
fi

if ! awk '/^\[tui\]/{inside_tui=1; next} /^\[/{inside_tui=0} inside_tui && /^notification_condition = "always"$/{found=1} END{exit found ? 0 : 1}' "$CONFIG_FILE"; then
  echo "Codex の許可待ち通知が、ターミナル操作中にも表示される設定になっていません。" >&2
  exit 1
fi

if [[ ! -x "$NOTIFY_SCRIPT" ]]; then
  echo "Codex の通知スクリプトが見つからないか、実行できません: $NOTIFY_SCRIPT" >&2
  exit 1
fi

if [[ ! -f "$HOOKS_FILE" ]]; then
  echo "Codex の hook 設定が見つかりません: $HOOKS_FILE" >&2
  exit 1
fi

if ! grep -Fq '"PermissionRequest"' "$HOOKS_FILE"; then
  echo "Codex の認証待ち hook が設定されていません。" >&2
  exit 1
fi

if ! grep -Fq '"Stop"' "$HOOKS_FILE"; then
  echo "Codex の作業完了 hook が設定されていません。" >&2
  exit 1
fi

if grep -Fq '"SubagentStop"' "$HOOKS_FILE"; then
  echo "Codex の subagent 完了 hook が設定されているため、subagent 完了でも通知音が鳴ります。" >&2
  exit 1
fi

if ! grep -Fq '"command": "bash /Users/ishiooon/dotfiles/.codex/scripts/codex_notify.sh --event=agent-turn-complete"' "$HOOKS_FILE"; then
  echo "Codex の作業完了 hook が、完了通知スクリプトを呼んでいません。" >&2
  exit 1
fi

if ! grep -Fq '"command": "bash /Users/ishiooon/dotfiles/.codex/scripts/codex_notify.sh --event=approval-requested"' "$HOOKS_FILE"; then
  echo "Codex の認証待ち hook が、完了通知と同じ通知スクリプトを呼んでいません。" >&2
  exit 1
fi

OUTPUT="$(bash "$NOTIFY_SCRIPT" --env=localdev --dry-run)"

if ! grep -Fq "osascript display notification" <<<"$OUTPUT"; then
  echo "Codex の通知スクリプトが macOS 通知を出す構成になっていません。" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

if ! grep -Fq "afplay /System/Library/Sounds/Glass.aiff" <<<"$OUTPUT"; then
  echo "Codex の通知スクリプトが完了音を鳴らす構成になっていません。" >&2
  echo "$OUTPUT" >&2
  exit 1
fi

APPROVAL_OUTPUT="$(bash "$NOTIFY_SCRIPT" --env=localdev --dry-run --event=approval-requested)"

if ! grep -Fq "Codex が認証待ちです。確認してください。" <<<"$APPROVAL_OUTPUT"; then
  echo "Codex の認証待ち通知が、認証待ちとして読める文面になっていません。" >&2
  echo "$APPROVAL_OUTPUT" >&2
  exit 1
fi

if ! grep -Fq "afplay /System/Library/Sounds/Glass.aiff" <<<"$APPROVAL_OUTPUT"; then
  echo "Codex の認証待ち通知が、作業完了と同じ通知音を鳴らす構成になっていません。" >&2
  echo "$APPROVAL_OUTPUT" >&2
  exit 1
fi

SUBAGENT_OUTPUT="$(bash "$NOTIFY_SCRIPT" --env=localdev --dry-run --event=subagent-stop)"

if [[ -n "$SUBAGENT_OUTPUT" ]]; then
  echo "Codex の subagent 完了通知が無音になっていません。" >&2
  echo "$SUBAGENT_OUTPUT" >&2
  exit 1
fi

echo "PASS: Codex は作業完了時と許可待ち時に通知を出せます。"
