#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"
MUSIC_CONTROL_ACTION="${MUSIC_CONTROL_ACTION:-}"
main() {
  parse_arguments "$@"
  if [[ -n "$MUSIC_CONTROL_ACTION" ]]; then
    run_music_control "$MUSIC_CONTROL_ACTION"
  fi
  update_music_items
}
parse_arguments() {
  while (($#)); do
    if parse_common_argument "$1"; then
      shift
      continue
    fi
    case "$1" in
      playpause)
        MUSIC_CONTROL_ACTION="$1"
        ;;
      *)
        fail "未対応の引数です: $1"
        ;;
    esac
    shift
  done
}
run_music_control() {
  local action="$1"
  case "$action" in
    playpause)
      if [[ "$DRY_RUN" == "true" ]]; then
        printf '+ osascript music playpause\n'
        return
      fi
      # Music.app の再生状態を切り替える。未起動の場合は起動してから再生状態を切り替える。
      osascript -e 'tell application "Music" to launch' -e 'tell application "Music" to playpause' >/dev/null 2>&1 || true
      ;;
    *)
      fail "未対応の Music 操作です: $action"
      ;;
  esac
}
update_music_items() {
  local music_data track artist state position duration

  # 曲名、再生アイコン、進捗線だけを更新し、popup 用項目は扱わない。
  music_data="$(read_music_data)"
  track="$(music_data_field "$music_data" 1)"
  artist="$(music_data_field "$music_data" 2)"
  state="$(music_data_field "$music_data" 3)"
  position="$(music_data_field "$music_data" 4)"
  duration="$(music_data_field "$music_data" 5)"
  run_command sketchybar --set music.toggle icon="$(playback_icon "$state")"
  run_command sketchybar --set "${NAME:-music.now}" label="$(display_label "$track" "$artist" "$state")"
  update_progress_item "$state" "$position" "$duration"
}
read_music_data() {
  # テストでは環境変数、通常実行では Music.app から曲情報を取得する。
  if [[ -n "${MUSIC_TRACK_NAME:-}" || -n "${MUSIC_PLAYER_STATE:-}" ]]; then
    read_music_data_from_environment
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'Not Playing\t\tstopped\t0\t0\n'
    return
  fi
  read_music_data_from_music_app
}
music_data_field() {
  local music_data="$1"
  local field_index="$2"
  printf '%s\n' "$music_data" | awk -F '\t' -v field_index="$field_index" '{ print $field_index }'
}
display_label() {
  local track="$1"
  local artist="$2"
  local state="$3"
  if [[ "$state" == "stopped" || "$track" == "Not Playing" ]]; then
    printf 'Not Playing\n'
    return
  fi
  if [[ -n "$artist" ]]; then
    printf '%s - %s\n' "$track" "$artist"
    return
  fi
  printf '%s\n' "$track"
}
playback_icon() {
  local state="$1"
  if [[ "$state" == "playing" ]]; then
    printf 'Ⅱ\n'
    return
  fi
  printf '▶\n'
}
update_progress_item() {
  local state="$1"
  local position="$2"
  local duration="$3"
  if ! progress_is_visible "$state" "$duration"; then
    run_command sketchybar --set music.progress drawing=off slider.percentage=0
    return
  fi
  # Music.app の再生位置を、曲名下の極細 slider へ反映する。
  run_command sketchybar --set music.progress drawing=on slider.percentage="$(progress_percentage "$position" "$duration")"
}
progress_is_visible() {
  local state="$1"
  local duration="$2"
  [[ "$state" != "stopped" && -n "$duration" && "$duration" != "0" ]] || return 1
  awk -v duration="$duration" 'BEGIN { exit(duration > 0 ? 0 : 1) }'
}
progress_percentage() {
  local position="$1"
  local duration="$2"
  awk -v position="$position" -v duration="$duration" '
    BEGIN {
      percentage = int((position / duration) * 100 + 0.5)
      if (percentage < 0) percentage = 0
      if (percentage > 100) percentage = 100
      print percentage
    }
  '
}
read_music_data_from_environment() {
  local track="${MUSIC_TRACK_NAME:-Not Playing}"
  local artist="${MUSIC_ARTIST_NAME:-}"
  local state="${MUSIC_PLAYER_STATE:-playing}"
  local position="${MUSIC_PLAYER_POSITION:-0}"
  local duration="${MUSIC_TRACK_DURATION:-0}"
  printf '%s\t%s\t%s\t%s\t%s\n' "$track" "$artist" "$state" "$position" "$duration"
}
read_music_data_from_music_app() {
  osascript <<'APPLESCRIPT' 2>/dev/null || printf 'Not Playing\t\tstopped\t0\t0\n'
set tabText to ASCII character 9
tell application "System Events" to set musicIsRunning to exists process "Music"
if musicIsRunning is false then return "Not Playing" & tabText & "" & tabText & "stopped" & tabText & "0" & tabText & "0"
tell application "Music"
  if player state is stopped then return "Not Playing" & tabText & "" & tabText & "stopped" & tabText & "0" & tabText & "0"
  return (name of current track) & tabText & (artist of current track) & tabText & (player state as text) & tabText & player position & tabText & duration of current track
end tell
APPLESCRIPT
}
main "$@"
