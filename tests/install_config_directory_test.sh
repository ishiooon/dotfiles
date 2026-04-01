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

# 実ホームを汚さないよう、一時ディレクトリ上に検証用の HOME を作成する。
TEMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

TEST_HOME="$TEMP_ROOT/home"
mkdir -p "$TEST_HOME"
ln -s "$ROOT_DIR" "$TEST_HOME/dotfiles"

# dotfiles インストーラーの前提に合わせ、最小限の初期ディレクトリを用意する。
mkdir -p "$TEST_HOME/.bash" "$TEST_HOME/.zsh"

# 一時 HOME 上でインストールを実行し、.config へ到達できることを確認する。
HOME="$TEST_HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" bash "$INSTALL_SCRIPT" >/dev/null

if [[ ! -L "$TEST_HOME/.config" ]]; then
  echo ".config がシンボリックリンクとして配置されていません。" >&2
  exit 1
fi

ACTUAL_TARGET="$(readlink "$TEST_HOME/.config")"
EXPECTED_TARGET="$TEST_HOME/dotfiles/.config"
if [[ "$ACTUAL_TARGET" != "$EXPECTED_TARGET" ]]; then
  echo ".config のリンク先が期待と一致しません。" >&2
  echo "期待値: $EXPECTED_TARGET" >&2
  echo "実際値: $ACTUAL_TARGET" >&2
  exit 1
fi

if [[ -e "$TEST_HOME/.aerospace.toml" || -L "$TEST_HOME/.aerospace.toml" ]]; then
  echo "不要な AeroSpace ルート設定リンクが作成されています。" >&2
  exit 1
fi

echo "PASS: .config は dotfiles の内容としてインストールされました。"
