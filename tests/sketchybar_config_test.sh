#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.config/sketchybar/sketchybarrc"
CONFIG_TEXT="$(find "$ROOT_DIR/.config/sketchybar" -maxdepth 2 -type f \( -name '*.sh' -o -name 'sketchybarrc' \) -print0 | xargs -0 cat)"

if [[ ! -x "$CONFIG_FILE" ]]; then
  echo "SketchyBar の設定ファイルが見つからないか、実行できません: $CONFIG_FILE" >&2
  exit 1
fi

# 見た目は固定値ではなく、少し透ける背景、ぼかし、角丸を使う方針だけを検証する。
for expected in "blur_radius=" "corner_radius=" "color=" "front.app" "system.memory" "system.cpu" "clock"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "SketchyBar の設定に必要な構成が含まれていません: $expected" >&2
    exit 1
  fi
done

# 過去の設定で作られた item は reload だけでは消えないため、現在使わない item を明示的に掃除する。
if ! grep -Fq 'sketchybar --remove "$stale_item"' "$CONFIG_FILE"; then
  echo "SketchyBar の設定が古い item を再読み込み前に削除していません。" >&2
  exit 1
fi

for stale_item in "music.waveform" "space.1" "space.5"; do
  if ! grep -Fq -- "$stale_item" "$CONFIG_FILE"; then
    echo "SketchyBar の設定が古い item を再読み込み前に掃除していません: $stale_item" >&2
    exit 1
  fi
done

# macOS の追加メニューバーアイコンを alias 化すると画面収録権限が必要になるため、設定から除外されていることを確認する。
for forbidden in "menu.extras.toggle" "menu_extras_setup.sh" "menu_extras_toggle.sh" "--add alias" "default_menu_items" "•••"; do
  if grep -Fq -- "$forbidden" <<<"$CONFIG_TEXT"; then
    echo "SketchyBar の設定に不要な追加アイコン展開機能が残っています: $forbidden" >&2
    exit 1
  fi
done

echo "PASS: SketchyBar の設定は半透明で懐かしい雰囲気を保ち、追加アイコン展開機能を含みません。"
