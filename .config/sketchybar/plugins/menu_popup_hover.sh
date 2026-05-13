#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"
source "$CONFIG_DIR/colors.sh"

main() {
  parse_arguments "$@"

  local parent_name
  parent_name="$(resolve_parent_name)"

  case "${SENDER:-}" in
    mouse.entered)
      cancel_popup_close "$parent_name"
      # popup 内の項目に入ったら、親項目から離れた後でも popup を開いたままにする。
      run_command sketchybar --set "$parent_name" popup.drawing=on
      clear_popup_hover_state "$parent_name"
      run_command sketchybar --set "$NAME" \
        background.drawing=on \
        background.color="$ACTIVE_BACKGROUND_COLOR" \
        background.corner_radius=5 \
        background.height=22
      ;;
    mouse.exited)
      # popup 内の別項目へ移るだけでは閉じず、項目の強調表示だけを戻す。
      run_command sketchybar --set "$NAME" background.drawing=off
      ;;
    mouse.exited.global)
      # popup 領域から外へ出た場合だけ、短い猶予の後に閉じる。
      run_command sketchybar --set "$NAME" background.drawing=off
      schedule_popup_close "$parent_name"
      ;;
  esac
}

parse_arguments() {
  while (($#)); do
    parse_common_argument "$1" || fail "未対応の引数です: $1"
    shift
  done
}

resolve_parent_name() {
  case "${NAME:-}" in
    apple.menu.*)
      printf 'apple.menu\n'
      ;;
    current.app.*)
      printf 'front.app\n'
      ;;
    music.playlist.* | music.queue.*)
      printf 'music.now\n'
      ;;
    codex.usage.*)
      printf 'codex.usage\n'
      ;;
    *)
      fail "親 popup を判定できない項目です: ${NAME:-}"
      ;;
  esac
}

main "$@"
