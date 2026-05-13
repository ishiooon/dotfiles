#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"

APPLE_MENU_ACTION="${APPLE_MENU_ACTION:-}"

main() {
  parse_arguments "$@"

  case "${SENDER:-}" in
    mouse.entered)
      close_other_popups "${NAME:-apple.menu}"
      cancel_popup_close "${NAME:-apple.menu}"
      # Apple メニューの項目にマウスポインターが乗ったときだけ、標準メニュー風の一覧を出す。
      clear_popup_hover_state "${NAME:-apple.menu}"
      run_command sketchybar --set "${NAME:-apple.menu}" popup.drawing=on
      ;;
    mouse.exited.global)
      # 親項目から popup へ移動する時間を残すため、閉じる処理を短く遅延させる。
      schedule_popup_close "${NAME:-apple.menu}"
      ;;
  esac

  if [[ -n "$APPLE_MENU_ACTION" ]]; then
    run_apple_menu_action "$APPLE_MENU_ACTION"
    close_popup apple.menu
  fi
}

parse_arguments() {
  while (($#)); do
    if parse_common_argument "$1"; then
      shift
      continue
    fi

    APPLE_MENU_ACTION="$1"
    shift
  done
}

run_apple_menu_action() {
  local action="$1"
  local primary_item
  local fallback_item

  case "$action" in
    about_this_mac)
      primary_item="About This Mac"
      fallback_item=""
      ;;
    system_settings)
      primary_item="System Settings..."
      fallback_item="System Settings"
      ;;
    app_store)
      primary_item="App Store..."
      fallback_item="App Store"
      ;;
    force_quit)
      primary_item="Force Quit..."
      fallback_item="Force Quit"
      ;;
    sleep)
      primary_item="Sleep"
      fallback_item=""
      ;;
    lock_screen)
      primary_item="Lock Screen"
      fallback_item=""
      ;;
    *)
      fail "未対応の Apple メニューアクションです: $action"
      ;;
  esac

  click_apple_menu_item "$primary_item" "$fallback_item"
}

click_apple_menu_item() {
  local primary_item="$1"
  local fallback_item="$2"

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+ osascript apple-menu %q %q\n' "$primary_item" "$fallback_item"
    return
  fi

  # SystemUIServer の Apple メニューを開き、macOS 標準メニューの項目を実行する。
  osascript - "$primary_item" "$fallback_item" <<'APPLESCRIPT'
on run argv
  set primaryItem to item 1 of argv
  set fallbackItem to item 2 of argv
  set candidateItems to {primaryItem, fallbackItem}

  tell application "System Events"
    tell application process "SystemUIServer"
      tell menu bar item 1 of menu bar 1
        click
        repeat with menuItemName in candidateItems
          if menuItemName is not "" and exists menu item menuItemName of menu 1 then
            click menu item menuItemName of menu 1
            return
          end if
        end repeat
      end tell
    end tell
  end tell
end run
APPLESCRIPT
}

main "$@"
