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

  case "${SENDER:-}" in
    mouse.entered)
      close_other_popups "${NAME:-music.now}"
      cancel_popup_close "${NAME:-music.now}"
      clear_popup_hover_state "${NAME:-music.now}"
      update_music_items
      run_command sketchybar --set "${NAME:-music.now}" popup.drawing=on
      return
      ;;
    mouse.exited.global)
      # 曲名から再生リストへ移動する時間を残すため、閉じる処理を短く遅延させる。
      schedule_popup_close "${NAME:-music.now}"
      return
      ;;
  esac

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

update_music_items() {
  local music_data header track artist playlist state display_label
  music_data="$(read_music_data)"
  header="$(printf '%s\n' "$music_data" | sed -n '1p')"
  IFS=$'\t' read -r track artist playlist state <<<"$header"

  display_label="$(build_display_label "$track" "$artist" "$state")"
  run_command sketchybar --set music.toggle icon="$(playback_icon "$state")"
  run_command sketchybar --set "${NAME:-music.now}" label="$display_label"
  run_command sketchybar --set music.playlist.title label="${playlist:-Music}"
  update_queue_items "$music_data"
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

read_music_data() {
  if [[ -n "${MUSIC_TRACK_NAME:-}" || -n "${MUSIC_QUEUE_TRACKS:-}" || -n "${MUSIC_PLAYER_STATE:-}" ]]; then
    read_music_data_from_environment
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'Not Playing\t\tMusic\tstopped\n'
    return
  fi

  read_music_data_from_music_app
}

read_music_data_from_environment() {
  local track="${MUSIC_TRACK_NAME:-Not Playing}"
  local artist="${MUSIC_ARTIST_NAME:-}"
  local playlist="${MUSIC_PLAYLIST_NAME:-Music}"
  local state="${MUSIC_PLAYER_STATE:-playing}"

  printf '%s\t%s\t%s\t%s\n' "$track" "$artist" "$playlist" "$state"
  printf '%s\n' "${MUSIC_QUEUE_TRACKS:-}" | sed '/^$/d' | sed -n '1,5p'
}

read_music_data_from_music_app() {
  osascript <<'APPLESCRIPT' 2>/dev/null || printf 'Not Playing\t\tMusic\tstopped\n'
set tabText to ASCII character 9
set lineText to ASCII character 10
tell application "System Events" to set musicIsRunning to exists process "Music"
if musicIsRunning is false then return "Not Playing" & tabText & "" & tabText & "Music" & tabText & "stopped"

tell application "Music"
  if player state is stopped then return "Not Playing" & tabText & "" & tabText & "Music" & tabText & "stopped"
  set trackName to name of current track
  set artistName to artist of current track
  set playlistName to "Music"
  try
    set playlistName to name of current playlist
  end try
  set outputText to trackName & tabText & artistName & tabText & playlistName & tabText & (player state as text)
  try
    set trackList to tracks of current playlist
    set currentId to persistent ID of current track
    set currentIndex to 1
    repeat with trackIndex from 1 to count of trackList
      if persistent ID of item trackIndex of trackList is currentId then
        set currentIndex to trackIndex
        exit repeat
      end if
    end repeat
    repeat with trackIndex from currentIndex to currentIndex + 4
      if trackIndex is greater than count of trackList then exit repeat
      set queueTrack to item trackIndex of trackList
      set outputText to outputText & lineText & (name of queueTrack) & " - " & (artist of queueTrack)
    end repeat
  end try
  return outputText
end tell
APPLESCRIPT
}

build_display_label() {
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

update_queue_items() {
  local music_data="$1"
  local queue_index queue_label

  for queue_index in 1 2 3 4 5; do
    queue_label="$(printf '%s\n' "$music_data" | sed -n "$((queue_index + 1))p")"
    if [[ -n "$queue_label" ]]; then
      run_command sketchybar --set "music.queue.$queue_index" drawing=on label="$queue_label"
    else
      run_command sketchybar --set "music.queue.$queue_index" drawing=off label=""
    fi
  done
}

main "$@"
