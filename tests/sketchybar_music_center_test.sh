#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_TEXT="$(find "$ROOT_DIR/.config/sketchybar" -maxdepth 2 -type f \( -name '*.sh' -o -name 'sketchybarrc' \) -print0 | xargs -0 cat)"
DISPLAY_TEXT="$(find "$ROOT_DIR/.config/sketchybar/items" "$ROOT_DIR/.config/sketchybar/plugins" -maxdepth 1 -type f -name '*.sh' -print0 | xargs -0 cat)"
MUSIC_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/music_now_playing.sh"
CENTER_ITEMS_FILE="$ROOT_DIR/.config/sketchybar/items/center.sh"

if ! awk '/for popup_item in/{inside_popup_loop=1} inside_popup_loop && /background.drawing=off/{found=1} inside_popup_loop && /^done$/{exit found ? 0 : 1}' "$CENTER_ITEMS_FILE"; then
  echo "Music の popup 項目が、再読み込み時にホバー表示を初期化していません。" >&2
  exit 1
fi

for forbidden in "--add space" "space.sh" "space.rail" "space."; do
  if grep -Fq -- "$forbidden" <<<"$DISPLAY_TEXT"; then
    echo "中央表示に不要な Space 表示が残っています: $forbidden" >&2
    exit 1
  fi
done

for forbidden in "--add graph" "music.waveform" "music_waveform.sh" "music.bar." "music_bars.sh"; do
  if grep -Fq -- "$forbidden" <<<"$DISPLAY_TEXT"; then
    echo "中央表示に不要な音声可視化が残っています: $forbidden" >&2
    exit 1
  fi
done

for expected in "--add item music.toggle center" "icon.padding_right=2" "--add item music.now center" "--add slider music.progress center 132" "label.padding_left=4" "label.padding_right=8" "width=132" "slider.background.height=1" "slider.knob=\"\"" "padding_left=-144" "padding_right=0" "music.status music.toggle music.now" "music_now_playing.sh" "MUSIC_CONTROL_ACTION=playpause"; do
  if ! grep -Fq -- "$expected" <<<"$CONFIG_TEXT"; then
    echo "中央の Music 表示に必要な構成が不足しています: $expected" >&2
    exit 1
  fi
done

for forbidden in "popup.music.now" "music.queue." "music.playlist.title" "mouse.entered" "mouse.exited" "menu_popup_hover.sh"; do
  if grep -Fq "$forbidden" <<<"$DISPLAY_TEXT"; then
    echo "中央の Music 表示に hover popup 用の構成が残っています: $forbidden" >&2
    exit 1
  fi
done

if grep -Fq "music.status music.toggle music.progress music.now" "$CENTER_ITEMS_FILE"; then
  echo "Music の背景に overlay 用の進捗線が含まれています。" >&2
  exit 1
fi

if ! awk '/--set music.now/{inside_music=1} inside_music && /label.padding_left=4/{left_found=1} inside_music && /label.padding_right=8/{right_found=1} inside_music && /--subscribe music.now/{exit(left_found && right_found ? 0 : 1)}' "$CENTER_ITEMS_FILE"; then
  echo "Music の曲情報に左右の余白が明示されていません。" >&2
  exit 1
fi

if ! awk '/--set music.progress/{inside_progress=1} inside_progress && /padding_left=-144/{left_found=1} inside_progress && /padding_right=0/{right_found=1} inside_progress && /^$/{exit(left_found && right_found ? 0 : 1)}' "$CENTER_ITEMS_FILE"; then
  echo "Music 進捗線が島の中心へ寄る余白設定になっていません。" >&2
  exit 1
fi

if ! awk '/--add item music.now center/{music_line=NR} /--add slider music.progress center 132/{progress_line=NR} END{exit(music_line > 0 && progress_line > music_line ? 0 : 1)}' "$CENTER_ITEMS_FILE"; then
  echo "Music 進捗線が曲情報の下へ重なる順序で配置されていません。" >&2
  exit 1
fi

MUSIC_OUTPUT="$(MUSIC_TRACK_NAME=Kaze MUSIC_ARTIST_NAME=Fujii MUSIC_PLAYER_POSITION=75 MUSIC_TRACK_DURATION=300 NAME=music.now bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
for expected in "music.toggle" "label=Kaze\\ -\\ Fujii" "music.progress" "slider.percentage=25" "drawing=on"; do
  if ! grep -Fq "$expected" <<<"$MUSIC_OUTPUT"; then
    echo "Music 表示スクリプトが曲情報または進捗線を更新していません: $expected" >&2
    echo "$MUSIC_OUTPUT" >&2
    exit 1
  fi
done

if grep -Fq "music.queue." <<<"$MUSIC_OUTPUT" || grep -Fq "music.playlist.title" <<<"$MUSIC_OUTPUT"; then
  echo "Music 表示スクリプトが不要な popup 用項目を更新しています。" >&2
  echo "$MUSIC_OUTPUT" >&2
  exit 1
fi

STOPPED_OUTPUT="$(MUSIC_PLAYER_STATE=stopped NAME=music.now bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "music.progress" <<<"$STOPPED_OUTPUT" || ! grep -Fq "drawing=off" <<<"$STOPPED_OUTPUT"; then
  echo "Music 停止中に進捗線を隠していません。" >&2
  echo "$STOPPED_OUTPUT" >&2
  exit 1
fi
if ! grep -Fq "label=Not\\ Playing" <<<"$STOPPED_OUTPUT"; then
  echo "Music 停止中の曲名表示を正しく更新していません。" >&2
  echo "$STOPPED_OUTPUT" >&2
  exit 1
fi

HOVER_OUTPUT="$(NAME=music.now SENDER=mouse.entered bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "popup.drawing=on" <<<"$HOVER_OUTPUT" || grep -Fq "close-other-popups" <<<"$HOVER_OUTPUT" || grep -Fq "clear-popup-hover" <<<"$HOVER_OUTPUT"; then
  echo "Music 表示がホバーで popup を開いています。" >&2
  exit 1
fi

EXIT_OUTPUT="$(NAME=music.now SENDER=mouse.exited bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
if grep -Fq "schedule-popup-close" <<<"$EXIT_OUTPUT" || grep -Fq "popup.drawing=off" <<<"$EXIT_OUTPUT"; then
  echo "Music 表示がマウス退出で popup を閉じようとしています。" >&2
  exit 1
fi

CONTROL_OUTPUT="$(MUSIC_CONTROL_ACTION=playpause NAME=music.now MUSIC_PLAYER_STATE=playing bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "osascript music playpause" <<<"$CONTROL_OUTPUT" || ! grep -Fq "music.toggle" <<<"$CONTROL_OUTPUT"; then
  echo "Music の再生停止切り替えボタンが動作しません。" >&2
  exit 1
fi

echo "PASS: SketchyBar は中央に再生中の曲情報だけを表示し、hover popup を開きません。"
