#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/.bin/install.sh"

# 検証対象が存在しない場合は即時失敗し、設定漏れを検知する。
if [[ ! -f "$INSTALL_SCRIPT" ]]; then
  echo "インストールスクリプトが見つかりません: $INSTALL_SCRIPT" >&2
  exit 1
fi

# シンボリックリンクの直接のリンク先が想定どおりかを確認する。
assert_link_target() {
  local link_path="$1"
  local expected_target="$2"

  if [[ ! -L "$link_path" ]]; then
    echo "シンボリックリンクとして配置されていません: $link_path" >&2
    exit 1
  fi

  local actual_target
  actual_target="$(readlink "$link_path")"
  if [[ "$actual_target" != "$expected_target" ]]; then
    echo "リンク先が期待と一致しません: $link_path" >&2
    echo "期待値: $expected_target" >&2
    echo "実際値: $actual_target" >&2
    exit 1
  fi
}

# 実ホームを汚さないよう、一時ディレクトリ上に検証用の HOME を作成する。
TEMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

TEST_HOME="$TEMP_ROOT/home"
mkdir -p "$TEST_HOME" "$TEST_HOME/.bash" "$TEST_HOME/.zsh"
ln -s "$ROOT_DIR" "$TEST_HOME/dotfiles"

# 一時 HOME 上でインストールを実行し、.agents を dotfiles 管理に寄せられることを確認する。
HOME="$TEST_HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash "$INSTALL_SCRIPT" >/dev/null

assert_link_target "$TEST_HOME/.agents" "$TEST_HOME/dotfiles/.agents"

# Codex の説明書とエージェント定義は、認証情報を含む状態全体ではなく管理対象だけをリンクする。
assert_link_target "$TEST_HOME/.codex/AGENTS.md" "$TEST_HOME/dotfiles/.codex/AGENTS.md"
assert_link_target "$TEST_HOME/.codex/agents" "$TEST_HOME/dotfiles/.codex/agents"
# 削除した Codex Skill が dotfiles の再インストールで復活しないことを確認する。
for removed_skill in superpowers hallmark; do
  if [[ -e "$TEST_HOME/.agents/skills/$removed_skill" || -L "$TEST_HOME/.agents/skills/$removed_skill" ]]; then
    echo "削除した Codex Skill が残っています: $removed_skill" >&2
    exit 1
  fi
done

echo "PASS: .agents は dotfiles 配下で管理され、削除した Codex Skill は再作成されません。"
