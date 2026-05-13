#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/.bin/install-sketchybar.sh"

if [[ ! -x "$INSTALL_SCRIPT" ]]; then
  echo "SketchyBar のインストール補助スクリプトが見つからないか、実行できません: $INSTALL_SCRIPT" >&2
  exit 1
fi

OUTPUT="$(bash "$INSTALL_SCRIPT" --env=localdev --dry-run)"

for expected in \
  "brew tap FelixKratz/formulae" \
  "brew install sketchybar" \
  "defaults write NSGlobalDomain _HIHideMenuBar -bool true" \
  "defaults -currentHost write NSGlobalDomain _HIHideMenuBar -bool true" \
  "brew services start sketchybar" \
  "sketchybar --reload"; do
  if ! grep -Fq "$expected" <<<"$OUTPUT"; then
    echo "ドライランに期待した導入手順が含まれていません: $expected" >&2
    echo "$OUTPUT" >&2
    exit 1
  fi
done

# 追加メニューバーアイコンの alias 表示は使わないため、画面収録権限を促す案内を出さない。
for forbidden in "Screen Recording" "画面収録" "alias 表示"; do
  if grep -Fq "$forbidden" <<<"$OUTPUT"; then
    echo "導入手順の出力に不要な画面収録権限の案内が含まれています: $forbidden" >&2
    echo "$OUTPUT" >&2
    exit 1
  fi
done

echo "PASS: SketchyBar のインストール補助スクリプトは導入とメニューバー自動非表示を確認できます。"
