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

  # 既に追跡済みのローカル状態ファイルも、除外ルールとして守られているかを検証する。
  if ! git check-ignore --no-index -q "$target_path"; then
    echo "除外されるべきパスが .gitignore から漏れています: $target_path" >&2
    exit 1
  fi
}

# 指定したパスが .gitignore によって誤って除外されていないことを確認する。
assert_not_ignored() {
  local target_path="$1"

  # 追跡状態に依存せず、共有したいパスが除外ルールに巻き込まれていないかを検証する。
  if git check-ignore --no-index -q "$target_path"; then
    echo "追跡したいパスまで .gitignore で除外されています: $target_path" >&2
    exit 1
  fi
}

# Claude 系のディレクトリはローカルの作業状態や設定を含むため、説明書以外をコミット対象外にする。
assert_ignored ".claude/backups/example.json"
assert_ignored ".claude/cache/example.md"
assert_ignored ".claude/debug/example.txt"
assert_ignored ".claude/settings.json"
assert_ignored ".claude/settings.local.json"
assert_ignored ".claude/statusline.sh"
assert_ignored ".claude/todos/example.json"
assert_not_ignored ".claude/CLAUDE.md"

# シェルや外部ツールのローカル設定は、認証情報を含む可能性があるため除外する。
assert_ignored ".bash/env.local.bash"
assert_ignored ".zsh/env.local.zsh"
assert_ignored ".config/mcphub/servers.json"

# Codex の SQLite 状態ファイルは会話履歴や実行状態を含むため、必ず除外する。
assert_ignored ".codex/state_security_test.sqlite"
assert_ignored ".codex/state_security_test.sqlite-shm"
assert_ignored ".codex/state_security_test.sqlite-wal"
assert_ignored ".codex/logs_security_test.sqlite"
assert_ignored ".codex/logs_security_test.sqlite-shm"
assert_ignored ".codex/logs_security_test.sqlite-wal"

# Codex の実行状態、履歴、キャッシュ、プラグインは機密情報やローカル状態を含むため除外する。
assert_ignored ".codex/.codex-global-state.json"
assert_ignored ".codex/.personality_migration"
assert_ignored ".codex/.tmp/plugins"
assert_ignored ".codex/ambient-suggestions/example.json"
assert_ignored ".codex/archived_sessions/example.jsonl"
assert_ignored ".codex/auth.json"
assert_ignored ".codex/browser/sessions/example.toml"
assert_ignored ".codex/cache/example.json"
assert_ignored ".codex/config.toml"
assert_ignored ".codex/history.jsonl"
assert_ignored ".codex/installation_id"
assert_ignored ".codex/keybindings.json"
assert_ignored ".codex/log/codex-tui.log"
assert_ignored ".codex/models_cache.json"
assert_ignored ".codex/plugins/cache/example/plugin.json"
assert_ignored ".codex/rules/default.rules"
assert_ignored ".codex/session_index.jsonl"
assert_ignored ".codex/sessions/2026/01/01/example.jsonl"
assert_ignored ".codex/sqlite/codex-dev.db"
assert_ignored ".codex/transcription-history.jsonl"
assert_ignored ".codex/vendor_imports/skills-curated-cache.json"
assert_ignored ".codex/version.json"

# Codex 系のディレクトリは認証情報、会話履歴、キャッシュを含み得るため、説明書以外をコミット対象外にする。
assert_ignored ".codex/skills/.system/example/SKILL.md"
assert_ignored ".codex/superpowers/skills/example/SKILL.md"
assert_not_ignored ".codex/AGENTS.md"

# テストコードとして追加した Lua ファイルは、引き続き追跡対象に含める。
assert_not_ignored "tests/gitignore_security_entries_test.lua"
assert_not_ignored "tests/nvim_neo_tree_git_refresh_test.lua"

# dotfiles で管理する Codex Skills の入口は、追跡対象から外してはいけない。
assert_not_ignored ".agents/skills/superpowers"

echo "PASS: セキュリティ上コミット不要な状態ファイルは除外され、Lua テストは追跡対象でした。"
