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
SOURCE_SKILLS_LINK="$ROOT_DIR/.agents/skills/superpowers"

# 検証対象が存在しない場合は即時失敗し、設定漏れを検知する。
if [[ ! -f "$INSTALL_SCRIPT" ]]; then
  echo "インストールスクリプトが見つかりません: $INSTALL_SCRIPT" >&2
  exit 1
fi

# dotfiles 側の skills 入口がシンボリックリンクとして管理されていることを確認する。
if [[ ! -L "$SOURCE_SKILLS_LINK" ]]; then
  echo "dotfiles 側の skills 入口が見つかりません: $SOURCE_SKILLS_LINK" >&2
  exit 1
fi

# 対象ディレクトリの実体パスを解決し、シンボリックリンク越しの到達先を比較できるようにする。
resolve_directory() {
  local target_dir="$1"

  (
    cd "$target_dir"
    pwd -P
  )
}

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

if [[ ! -d "$TEST_HOME/.agents/skills/superpowers" ]]; then
  echo "superpowers の skills ディレクトリへ到達できません。" >&2
  exit 1
fi

ACTUAL_SKILLS_DIR="$(resolve_directory "$TEST_HOME/.agents/skills/superpowers")"
EXPECTED_SKILLS_DIR="$(resolve_directory "$TEST_HOME/dotfiles/.codex/superpowers/skills")"
if [[ "$ACTUAL_SKILLS_DIR" != "$EXPECTED_SKILLS_DIR" ]]; then
  echo "superpowers skills の到達先が期待と一致しません。" >&2
  echo "期待値: $EXPECTED_SKILLS_DIR" >&2
  echo "実際値: $ACTUAL_SKILLS_DIR" >&2
  exit 1
fi

echo "PASS: .agents は dotfiles 配下で管理され、superpowers skills へ到達できました。"
