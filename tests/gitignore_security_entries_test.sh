#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 指定したパスが .gitignore によって除外されることを確認する。
assert_ignored() {
  local target_path="$1"

  if ! git check-ignore -q "$target_path"; then
    echo "除外されるべきパスが .gitignore から漏れています: $target_path" >&2
    exit 1
  fi
}

# 指定したパスが .gitignore によって誤って除外されていないことを確認する。
assert_not_ignored() {
  local target_path="$1"

  if git check-ignore -q "$target_path"; then
    echo "追跡したいパスまで .gitignore で除外されています: $target_path" >&2
    exit 1
  fi
}

# Claude 系のローカル作業データは引き続きコミット対象外であることを確認する。
assert_ignored ".claude/backups/example.json"
assert_ignored ".claude/debug/example.txt"
assert_ignored ".claude/todos/example.json"

# Codex の SQLite 状態ファイルは会話履歴や実行状態を含むため、必ず除外する。
assert_ignored ".codex/state_security_test.sqlite"
assert_ignored ".codex/state_security_test.sqlite-shm"
assert_ignored ".codex/state_security_test.sqlite-wal"
assert_ignored ".codex/logs_security_test.sqlite"
assert_ignored ".codex/logs_security_test.sqlite-shm"
assert_ignored ".codex/logs_security_test.sqlite-wal"

# テストコードとして追加した Lua ファイルは、引き続き追跡対象に含める。
assert_not_ignored "tests/gitignore_security_entries_test.lua"
assert_not_ignored "tests/nvim_neo_tree_git_refresh_test.lua"

# dotfiles で管理する Codex Skills の入口は、追跡対象から外してはいけない。
assert_not_ignored ".agents/skills/superpowers"

echo "PASS: セキュリティ上コミット不要な状態ファイルは除外され、Lua テストは追跡対象でした。"
