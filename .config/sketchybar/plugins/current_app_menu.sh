#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"

CURRENT_APP_ACTION="${CURRENT_APP_ACTION:-}"

main() {
  parse_arguments "$@"

  if [[ "${SENDER:-}" == "mouse.exited.global" ]]; then
    # 親項目から popup へ移動する時間を残すため、閉じる処理を短く遅延させる。
    schedule_popup_close "${NAME:-front.app}"
    return
  fi

  local app_name
  app_name="$(read_frontmost_app_name)"

  if [[ -n "$CURRENT_APP_ACTION" ]]; then
    run_current_app_action "$app_name" "$CURRENT_APP_ACTION"
    close_popup front.app
    return
  fi

  update_current_app_labels "$app_name"
  if [[ "${SENDER:-}" == "mouse.entered" ]]; then
    close_other_popups "${NAME:-front.app}"
    cancel_popup_close "${NAME:-front.app}"
    # ホバー開始時に最新のアプリ名へ揃えてから、操作メニューを表示する。
    clear_popup_hover_state "${NAME:-front.app}"
    run_command sketchybar --set "${NAME:-front.app}" popup.drawing=on
  fi
}

parse_arguments() {
  while (($#)); do
    if parse_common_argument "$1"; then
      shift
      continue
    fi

    case "$1" in
      about | settings | hide | hide_others | show_all | quit)
        CURRENT_APP_ACTION="$1"
        ;;
      *)
        fail "未対応の引数です: $1"
        ;;
    esac
    shift
  done
}

read_frontmost_app_name() {
  if [[ -n "${INFO:-}" ]]; then
    printf '%s\n' "$INFO"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'Finder\n'
    return
  fi

  osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || printf 'Finder\n'
}

update_current_app_labels() {
  local app_name="$1"

  # 前面アプリ名と、そのアプリメニューに並ぶ基本操作名を同時に更新する。
  run_command sketchybar --set "${NAME:-front.app}" label="$app_name"
  run_command sketchybar --set current.app.about label="About $app_name"
  run_command sketchybar --set current.app.settings label="Settings..."
  run_command sketchybar --set current.app.hide label="Hide $app_name"
  run_command sketchybar --set current.app.hide_others label="Hide Others"
  run_command sketchybar --set current.app.show_all label="Show All"
  run_command sketchybar --set current.app.quit label="Quit $app_name"
}

run_current_app_action() {
  local app_name="$1"
  local action="$2"
  local primary_item
  local fallback_item=""

  case "$action" in
    about)
      primary_item="About $app_name"
      ;;
    settings)
      primary_item="Settings..."
      fallback_item="Preferences..."
      ;;
    hide)
      primary_item="Hide $app_name"
      ;;
    hide_others)
      primary_item="Hide Others"
      ;;
    show_all)
      primary_item="Show All"
      ;;
    quit)
      primary_item="Quit $app_name"
      ;;
    *)
      fail "未対応の前面アプリアクションです: $action"
      ;;
  esac

  click_current_app_menu_item "$app_name" "$primary_item" "$fallback_item"
}

click_current_app_menu_item() {
  local app_name="$1"
  local primary_item="$2"
  local fallback_item="$3"

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+ osascript current-app %q %q %q\n' "$app_name" "$primary_item" "$fallback_item"
    return
  fi

  # System Events で前面アプリのアプリメニューを開き、指定項目を実行する。
  osascript - "$app_name" "$primary_item" "$fallback_item" <<'APPLESCRIPT'
on run argv
  set appName to item 1 of argv
  set primaryItem to item 2 of argv
  set fallbackItem to item 3 of argv
  set candidateItems to {primaryItem, fallbackItem}

  tell application "System Events"
    tell application process appName
      set frontmost to true
      tell menu bar item appName of menu bar 1
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
