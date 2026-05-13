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
APPLE_MENU_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/apple_menu_action.sh"
POPUP_HOVER_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/menu_popup_hover.sh"
RESTART_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/restart_sketchybar.sh"
LEFT_ITEMS_FILE="$ROOT_DIR/.config/sketchybar/items/left.sh"

if ! awk '/for popup_item in/{inside_popup_loop=1} inside_popup_loop && /background.drawing=off/{found=1} inside_popup_loop && /^done$/{exit found ? 0 : 1}' "$LEFT_ITEMS_FILE"; then
  echo "Apple メニューと前面アプリメニューの popup 項目が、再読み込み時にホバー表示を初期化していません。" >&2
  exit 1
fi

CURRENT_OUTPUT="$(INFO=Safari NAME=front.app bash "$CURRENT_APP_SCRIPT" --env=localdev --dry-run)"
for expected in "label=Safari" "current.app.about" "label=About\\ Safari" "label=Settings..." "label=Hide\\ Safari" "label=Show\\ All" "label=Quit\\ Safari"; do
  if ! grep -Fq "$expected" <<<"$CURRENT_OUTPUT"; then
    echo "前面アプリメニューの表示更新が不足しています: $expected" >&2
    exit 1
  fi
done

HOVER_OUTPUT="$(NAME=front.app SENDER=mouse.entered bash "$CURRENT_APP_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "popup.drawing=on" <<<"$HOVER_OUTPUT"; then
  echo "前面アプリメニューがホバー開始で開きません。" >&2
  exit 1
fi
if ! grep -Fq "close-other-popups front.app" <<<"$HOVER_OUTPUT"; then
  echo "前面アプリメニューを開いたときに、ほかの popup を閉じていません。" >&2
  exit 1
fi
if ! grep -Fq "clear-popup-hover front.app" <<<"$HOVER_OUTPUT" || ! grep -Fq "current.app.quit background.drawing=off" <<<"$HOVER_OUTPUT"; then
  echo "前面アプリメニューを開いたときに、前回残った項目ホバー表示を消していません。" >&2
  exit 1
fi

EXIT_OUTPUT="$(NAME=front.app SENDER=mouse.exited.global bash "$CURRENT_APP_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "schedule-popup-close front.app" <<<"$EXIT_OUTPUT" || ! grep -Fq "clear-popup-hover front.app" <<<"$EXIT_OUTPUT" || grep -Fq "front.app popup.drawing=off" <<<"$EXIT_OUTPUT"; then
  echo "前面アプリメニューの親項目が遅延なしで閉じる構成になっています。" >&2
  exit 1
fi

POPUP_ENTER_OUTPUT="$(NAME=current.app.quit SENDER=mouse.entered bash "$POPUP_HOVER_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "cancel-popup-close front.app" <<<"$POPUP_ENTER_OUTPUT" || ! grep -Fq -- "--set front.app" <<<"$POPUP_ENTER_OUTPUT" || ! grep -Fq "popup.drawing=on" <<<"$POPUP_ENTER_OUTPUT" || ! grep -Fq "background.drawing=on" <<<"$POPUP_ENTER_OUTPUT"; then
  echo "前面アプリの popup 項目がホバー中にメニュー表示を維持できません。" >&2
  exit 1
fi

POPUP_EXIT_OUTPUT="$(NAME=current.app.quit SENDER=mouse.exited bash "$POPUP_HOVER_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "schedule-popup-close front.app" <<<"$POPUP_EXIT_OUTPUT" || ! grep -Fq "background.drawing=off" <<<"$POPUP_EXIT_OUTPUT"; then
  echo "前面アプリの popup 項目間を移動しただけで閉じる予約が入っています。" >&2
  exit 1
fi

POPUP_GLOBAL_EXIT_OUTPUT="$(NAME=current.app.quit SENDER=mouse.exited.global bash "$POPUP_HOVER_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "schedule-popup-close front.app" <<<"$POPUP_GLOBAL_EXIT_OUTPUT" || ! grep -Fq "background.drawing=off" <<<"$POPUP_GLOBAL_EXIT_OUTPUT"; then
  echo "前面アプリの popup 領域から外へ出たときに閉じる予約が入りません。" >&2
  exit 1
fi

ACTION_OUTPUT="$(INFO=Safari CURRENT_APP_ACTION=quit bash "$CURRENT_APP_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "Quit\\ Safari" <<<"$ACTION_OUTPUT"; then
  echo "前面アプリメニューが現在アプリの終了項目を実行できません。" >&2
  exit 1
fi
if ! grep -Fq "clear-popup-hover front.app" <<<"$ACTION_OUTPUT" || ! grep -Fq "front.app popup.drawing=off" <<<"$ACTION_OUTPUT"; then
  echo "前面アプリメニューの項目実行後に、残ったホバー表示を消していません。" >&2
  exit 1
fi

APPLE_OUTPUT="$(APPLE_MENU_ACTION=about_this_mac bash "$APPLE_MENU_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "About\\ This\\ Mac" <<<"$APPLE_OUTPUT"; then
  echo "Apple メニューが標準の About This Mac 項目を実行できません。" >&2
  exit 1
fi
if ! grep -Fq "clear-popup-hover apple.menu" <<<"$APPLE_OUTPUT" || ! grep -Fq "apple.menu popup.drawing=off" <<<"$APPLE_OUTPUT"; then
  echo "Apple メニューの項目実行後に、残ったホバー表示を消していません。" >&2
  exit 1
fi

APP_STORE_OUTPUT="$(APPLE_MENU_ACTION=app_store bash "$APPLE_MENU_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "App\\ Store" <<<"$APP_STORE_OUTPUT"; then
  echo "Apple メニューが標準の App Store 項目を実行できません。" >&2
  exit 1
fi

APPLE_EXIT_OUTPUT="$(NAME=apple.menu SENDER=mouse.exited.global bash "$APPLE_MENU_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "schedule-popup-close apple.menu" <<<"$APPLE_EXIT_OUTPUT" || ! grep -Fq "clear-popup-hover apple.menu" <<<"$APPLE_EXIT_OUTPUT" || grep -Fq "apple.menu popup.drawing=off" <<<"$APPLE_EXIT_OUTPUT"; then
  echo "Apple メニューの親項目が遅延なしで閉じる構成になっています。" >&2
  exit 1
fi

APPLE_HOVER_OUTPUT="$(NAME=apple.menu SENDER=mouse.entered bash "$APPLE_MENU_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "close-other-popups apple.menu" <<<"$APPLE_HOVER_OUTPUT" || ! grep -Fq "popup.drawing=on" <<<"$APPLE_HOVER_OUTPUT"; then
  echo "Apple メニューを開いたときに、ほかの popup を閉じてから表示していません。" >&2
  exit 1
fi
if ! grep -Fq "clear-popup-hover apple.menu" <<<"$APPLE_HOVER_OUTPUT" || ! grep -Fq "apple.menu.app_store background.drawing=off" <<<"$APPLE_HOVER_OUTPUT" || ! grep -Fq "current.app.quit background.drawing=off" <<<"$APPLE_HOVER_OUTPUT"; then
  echo "Apple メニューを開いたときに、残った項目ホバー表示を消していません。" >&2
  exit 1
fi

APPLE_POPUP_EXIT_OUTPUT="$(NAME=apple.menu.app_store SENDER=mouse.exited bash "$POPUP_HOVER_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "schedule-popup-close apple.menu" <<<"$APPLE_POPUP_EXIT_OUTPUT" || ! grep -Fq "background.drawing=off" <<<"$APPLE_POPUP_EXIT_OUTPUT"; then
  echo "Apple メニューの popup 項目間を移動しただけで閉じる予約が入っています。" >&2
  exit 1
fi

APPLE_POPUP_GLOBAL_EXIT_OUTPUT="$(NAME=apple.menu.app_store SENDER=mouse.exited.global bash "$POPUP_HOVER_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "schedule-popup-close apple.menu" <<<"$APPLE_POPUP_GLOBAL_EXIT_OUTPUT" || ! grep -Fq "clear-popup-hover apple.menu" <<<"$APPLE_POPUP_GLOBAL_EXIT_OUTPUT" || ! grep -Fq "background.drawing=off" <<<"$APPLE_POPUP_GLOBAL_EXIT_OUTPUT"; then
  echo "Apple メニューの popup 領域から外へ出たときに閉じる予約が入りません。" >&2
  exit 1
fi

RESTART_OUTPUT="$(bash "$RESTART_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "killall sketchybar" <<<"$RESTART_OUTPUT"; then
  echo "Apple メニューから SketchyBar を実プロセスごと再起動できません。" >&2
  exit 1
fi

echo "PASS: SketchyBar の Apple メニューと前面アプリメニューはホバー表示とアクセシビリティ操作に対応しています。"
