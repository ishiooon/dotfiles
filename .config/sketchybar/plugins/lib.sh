#!/usr/bin/env bash

# 各プラグインの dry-run 出力を揃え、テストで SketchyBar へ実際に書き込まないようにする。
DRY_RUN="${DRY_RUN:-false}"

parse_common_argument() {
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --env=localdev)
      # テスト実行時に明示する環境指定。通常の表示更新には影響させない。
      ;;
    *)
      return 1
      ;;
  esac
}

run_command() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    return
  fi

  "$@"
}

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

schedule_popup_close() {
  local parent_name="$1"
  local delay="${POPUP_CLOSE_DELAY_SECONDS:-0.45}"
  local token
  token="$$-${RANDOM:-0}-$(date +%s)"

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+ schedule-popup-close %s %s\n' "$parent_name" "$delay"
    clear_popup_hover_state "$parent_name"
    return
  fi

  mkdir -p "$(popup_state_dir)"
  printf '%s\n' "$token" >"$(popup_state_file "$parent_name")"
  (
    sleep "$delay"
    if [[ "$(cat "$(popup_state_file "$parent_name")" 2>/dev/null || true)" == "$token" ]]; then
      close_popup "$parent_name"
    fi
  ) >/dev/null 2>&1 &
}

cancel_popup_close() {
  local parent_name="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+ cancel-popup-close %s\n' "$parent_name"
    return
  fi

  rm -f "$(popup_state_file "$parent_name")"
}

close_other_popups() {
  local current_parent_name="$1"
  local parent_name

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+ close-other-popups %s\n' "$current_parent_name"
  fi

  for parent_name in $(popup_parent_names); do
    if [[ "$parent_name" == "$current_parent_name" ]]; then
      continue
    fi

    # ほかの親メニューに残っている遅延クローズ予約を消し、開いたままの popup を閉じる。
    cancel_popup_close "$parent_name"
    close_popup "$parent_name"
  done
}

close_popup() {
  local parent_name="$1"

  clear_popup_hover_state "$parent_name"
  run_command sketchybar --set "$parent_name" popup.drawing=off
}

clear_popup_hover_state() {
  local parent_name="$1"
  local child_name

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+ clear-popup-hover %s\n' "$parent_name"
  fi

  for child_name in $(popup_child_names "$parent_name"); do
    run_command sketchybar --set "$child_name" background.drawing=off
  done
}

popup_parent_names() {
  printf '%s\n' \
    apple.menu \
    front.app \
    music.now \
    codex.usage
}

popup_child_names() {
  case "$1" in
    apple.menu)
      printf '%s\n' \
        apple.menu.about_this_mac \
        apple.menu.system_settings \
        apple.menu.app_store \
        apple.menu.force_quit \
        apple.menu.sleep \
        apple.menu.lock_screen \
        apple.menu.restart_sketchybar
      ;;
    front.app)
      printf '%s\n' \
        current.app.about \
        current.app.settings \
        current.app.hide \
        current.app.hide_others \
        current.app.show_all \
        current.app.quit
      ;;
    music.now)
      printf '%s\n' \
        music.playlist.title \
        music.queue.1 \
        music.queue.2 \
        music.queue.3 \
        music.queue.4 \
        music.queue.5
      ;;
    codex.usage)
      printf '%s\n' \
        codex.usage.five_hour \
        codex.usage.weekly
      ;;
    *)
      fail "子項目を判定できない popup です: $1"
      ;;
  esac
}

popup_state_dir() {
  printf '%s/sketchybar\n' "${TMPDIR:-/tmp}"
}

popup_state_file() {
  local parent_name="$1"
  printf '%s/popup-close-%s.state\n' "$(popup_state_dir)" "$parent_name"
}
