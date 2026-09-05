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

# 実リポジトリを後片付けでたどらないよう、全管理対象を一時 fixture に用意する。
TEMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

DOTFILES_FIXTURE="$TEMP_ROOT/dotfiles"
TEST_HOME="$TEMP_ROOT/home"
mkdir -p "$DOTFILES_FIXTURE"/{.agents,.bash,.claude,.config,.codex/agents,.zsh,.bin} "$TEST_HOME"
for source_path in .bashrc .zshrc .config/settings .bin/tool .claude/CLAUDE.md .agents/skill.md .codex/AGENTS.md .codex/agents/example.toml .mcp.json; do
  mkdir -p "$DOTFILES_FIXTURE/$(dirname "$source_path")"
  printf '%s\n' "fixture" > "$DOTFILES_FIXTURE/$source_path"
done
ln -s "$DOTFILES_FIXTURE" "$TEST_HOME/dotfiles"

# install.sh が管理するリンクの一覧を、実際の振る舞いとして確認する。
EXPECTED_LINKS=(
  .bashrc .zshrc .bash .zsh .config .bin .claude .agents
  .codex/AGENTS.md .codex/agents .mcp.json
)
HOME="$TEST_HOME" DOTFILES_INSTALL_ROOT="$TEST_HOME/dotfiles" bash "$INSTALL_SCRIPT" --env=localdev >/dev/null

for relative_path in "${EXPECTED_LINKS[@]}"; do
  link_path="$TEST_HOME/$relative_path"
  expected_target="$TEST_HOME/dotfiles/$relative_path"
  if [[ ! -L "$link_path" ]]; then
    echo "管理対象がリンクされていません: $relative_path" >&2
    exit 1
  fi
  if [[ "$(readlink "$link_path")" != "$expected_target" ]]; then
    echo "リンク先が期待と一致しません: $relative_path" >&2
    exit 1
  fi
done

echo "PASS: install.sh は全ての管理対象リンクを作成します。"
