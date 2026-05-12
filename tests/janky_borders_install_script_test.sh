#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/.bin/install-janky-borders.sh"

# インストール補助スクリプトが無い場合は、JankyBorders の導入手順を再現できない。
if [[ ! -f "$INSTALL_SCRIPT" ]]; then
  echo "JankyBorders のインストール補助スクリプトが見つかりません: $INSTALL_SCRIPT" >&2
  exit 1
fi

# 実行権限を確認し、手元のターミナルから直接呼び出せる状態を保つ。
if [[ ! -x "$INSTALL_SCRIPT" ]]; then
  echo "JankyBorders のインストール補助スクリプトに実行権限がありません: $INSTALL_SCRIPT" >&2
  exit 1
fi

# ドライランでは Homebrew を実行せず、実環境を汚さずに導入手順だけを確認する。
OUTPUT="$(bash "$INSTALL_SCRIPT" --env=localdev --dry-run)"

for expected in \
  "brew tap FelixKratz/formulae" \
  "brew install borders" \
  "brew services start borders" \
  "borders"; do
  if ! grep -Fq "$expected" <<<"$OUTPUT"; then
    echo "ドライランに期待した手順が含まれていません: $expected" >&2
    echo "実際の出力:" >&2
    echo "$OUTPUT" >&2
    exit 1
  fi
done

echo "PASS: JankyBorders のインストール補助スクリプトは Homebrew 導入手順を確認できます。"
