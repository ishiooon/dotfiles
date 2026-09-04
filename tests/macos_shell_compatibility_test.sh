#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 新しい Mac でエラーになる固定パスや GNU 専用指定を共有設定へ戻さないことを確認する。
if grep -Fq 'alias gh="/usr/local/bin/gh"' "$ROOT_DIR/.bashrc" "$ROOT_DIR/.zshrc"; then
  echo "GitHub CLI の実行パスが Intel Mac 固定になっています。" >&2
  exit 1
fi

if ! grep -Fq 'if [ -f "$HOME/.cargo/env" ]' "$ROOT_DIR/.bashrc"; then
  echo "Cargo の設定ファイルを存在確認なしで読み込んでいます。" >&2
  exit 1
fi

if ! grep -Fq "alias tac='gtac'" "$ROOT_DIR/.bash/aliases.bash"; then
  echo "macOS の Bash で GNU の tac を利用する別名がありません。" >&2
  exit 1
fi

if ! grep -Fq 'OSTYPE' "$ROOT_DIR/.zsh/aliases.zsh"; then
  echo "zsh の ls と grep が macOS と他の OS で分岐していません。" >&2
  exit 1
fi

echo "PASS: macOS のシェル設定は実行パスと GNU 専用コマンドを安全に扱います。"
