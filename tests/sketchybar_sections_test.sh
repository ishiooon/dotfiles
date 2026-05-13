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
LEFT_ITEMS_FILE="$ROOT_DIR/.config/sketchybar/items/left.sh"
APPLE_MENU_BLOCK="$(awk '/--add item apple.menu left/{capture=1} capture{print} /--subscribe apple.menu/{capture=0}' "$LEFT_ITEMS_FILE")"
FRONT_APP_BLOCK="$(awk '/--add item front.app left/{capture=1} capture{print} /--subscribe front.app/{capture=0}' "$LEFT_ITEMS_FILE")"

# 左端の Apple メニューは macOS 標準の入口に近づけ、ホバーだけで開く。
for expected in "apple.menu" "popup.apple.menu" "apple.menu.about_this_mac" "apple.menu.system_settings" "apple.menu.app_store" "apple.menu.force_quit" "apple.menu.lock_screen" "apple.menu.restart_sketchybar" "restart_sketchybar.sh" "apple_menu_action.sh"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "左端の Apple メニューに必要な構成が不足しています: $expected" >&2
    exit 1
  fi
done

for expected in "popup.front.app" "current.app.about" "current.app.settings" "current.app.hide" "current.app.show_all" "current.app.quit" "current_app_menu.sh"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "前面アプリメニューに必要な構成が不足しています: $expected" >&2
    exit 1
  fi
done

for expected in "mouse.entered" "mouse.exited" "popup.drawing=on" "popup.drawing=off"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "左側メニューがホバーで開閉する構成になっていません: $expected" >&2
    exit 1
  fi
done

if ! grep -Fq "mouse.exited.global" <<<"$APPLE_MENU_BLOCK$FRONT_APP_BLOCK"; then
  echo "左側メニューの親項目が外へ逃げたときの遅延クローズに対応していません。" >&2
  exit 1
fi

if ! grep -Fq "menu_popup_hover.sh" <<<"$CONFIG_TEXT"; then
  echo "popup 内の項目がホバー中の表示維持に対応していません。" >&2
  exit 1
fi

if ! grep -Fq "icon.drawing=off" <<<"$FRONT_APP_BLOCK" || grep -Fq 'icon="◆"' <<<"$FRONT_APP_BLOCK"; then
  echo "前面アプリ名の左に不要なダイヤアイコンが残っています。" >&2
  exit 1
fi

for expected in "background.padding_left=" "background.padding_right=" "padding_right="; do
  if ! grep -Fq "$expected" <<<"$APPLE_MENU_BLOCK"; then
    echo "Apple アイコンの背景に必要な余白が不足しています: $expected" >&2
    exit 1
  fi
done

if grep -Fq "popup.drawing=toggle" <<<"$CONFIG_TEXT"; then
  echo "左側メニューにクリックで開閉する古い設定が残っています。" >&2
  exit 1
fi

for expected in "--add bracket telemetry.status" "system.memory" "system.cpu" "codex.usage" "clock"; do
  if ! grep -Fq -- "$expected" <<<"$CONFIG_TEXT"; then
    echo "右側の telemetry island に必要な構成が不足しています: $expected" >&2
    exit 1
  fi
done

echo "PASS: SketchyBar は左にホバー式メニュー、右に telemetry island を持っています。"
