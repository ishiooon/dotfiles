#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT_APP_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/current_app_menu.sh"
PLUGIN_DIR="$ROOT_DIR/.config/sketchybar/plugins"
LEFT_ITEMS_FILE="$ROOT_DIR/.config/sketchybar/items/left.sh"

for removed_script in "$PLUGIN_DIR/apple_menu_action.sh" "$PLUGIN_DIR/menu_popup_hover.sh" "$PLUGIN_DIR/restart_sketchybar.sh"; do
  if [[ -e "$removed_script" ]]; then
    echo "ホバー popup 専用スクリプトが残っています: $removed_script" >&2
    exit 1
  fi
done

for forbidden in "popup." "mouse.entered" "mouse.exited" "current.app." "apple.menu.about_this_mac"; do
  if grep -Fq "$forbidden" "$LEFT_ITEMS_FILE"; then
    echo "左側アイテムに hover popup 用の構成が残っています: $forbidden" >&2
    exit 1
  fi
done

if ! grep -Fq -- "--subscribe front.app front_app_switched" "$LEFT_ITEMS_FILE"; then
  echo "前面アプリ名がアプリ切り替えイベントだけを購読していません。" >&2
  exit 1
fi

CURRENT_OUTPUT="$(INFO=Safari NAME=front.app bash "$CURRENT_APP_SCRIPT" --env=localdev --dry-run)"
for expected in "--set front.app" "label=Safari"; do
  if ! grep -Fq -- "$expected" <<<"$CURRENT_OUTPUT"; then
    echo "前面アプリ名の表示更新が不足しています: $expected" >&2
    exit 1
  fi
done

HOVER_OUTPUT="$(NAME=front.app SENDER=mouse.entered bash "$CURRENT_APP_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "popup.drawing=on" <<<"$HOVER_OUTPUT" || grep -Fq "close-other-popups" <<<"$HOVER_OUTPUT" || grep -Fq "clear-popup-hover" <<<"$HOVER_OUTPUT"; then
  echo "前面アプリ名がホバーで popup を開いています。" >&2
  exit 1
fi

EXIT_OUTPUT="$(NAME=front.app SENDER=mouse.exited.global bash "$CURRENT_APP_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "schedule-popup-close" <<<"$EXIT_OUTPUT" || grep -Fq "popup.drawing=off" <<<"$EXIT_OUTPUT"; then
  echo "前面アプリ名がマウス退出で popup を閉じようとしています。" >&2
  exit 1
fi

echo "PASS: SketchyBar の左側表示は hover popup を持たず、前面アプリ名だけを更新します。"
