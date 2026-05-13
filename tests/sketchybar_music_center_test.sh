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

for expected in "--add item music.toggle center" "--add item music.now center" "popup.music.now" "music.queue.1" "music_now_playing.sh" "MUSIC_CONTROL_ACTION=playpause"; do
  if ! grep -Fq -- "$expected" <<<"$CONFIG_TEXT"; then
    echo "中央の Music 表示に必要な構成が不足しています: $expected" >&2
    exit 1
  fi
done

MUSIC_OUTPUT="$(MUSIC_TRACK_NAME=Kaze MUSIC_ARTIST_NAME=Fujii MUSIC_PLAYLIST_NAME=Favorites MUSIC_QUEUE_TRACKS=$'Kaze - Fujii\nGrace - Fujii' NAME=music.now bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
for expected in "music.toggle" "label=Kaze\\ -\\ Fujii" "music.playlist.title" "label=Favorites" "music.queue.1" "label=Kaze\\ -\\ Fujii" "music.queue.2" "label=Grace\\ -\\ Fujii"; do
  if ! grep -Fq "$expected" <<<"$MUSIC_OUTPUT"; then
    echo "Music 表示スクリプトが曲情報または再生リストを更新していません: $expected" >&2
    echo "$MUSIC_OUTPUT" >&2
    exit 1
  fi
done

HOVER_OUTPUT="$(NAME=music.now SENDER=mouse.entered bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq -- "--set music.now" <<<"$HOVER_OUTPUT" || ! grep -Fq "popup.drawing=on" <<<"$HOVER_OUTPUT"; then
  echo "Music 表示がホバーで再生リストを開けません。" >&2
  exit 1
fi
if ! grep -Fq "close-other-popups music.now" <<<"$HOVER_OUTPUT"; then
  echo "Music 表示を開いたときに、ほかの popup を閉じていません。" >&2
  exit 1
fi
if ! grep -Fq "clear-popup-hover music.now" <<<"$HOVER_OUTPUT" || ! grep -Fq "music.queue.1 background.drawing=off" <<<"$HOVER_OUTPUT"; then
  echo "Music 表示を開いたときに、前回残った項目ホバー表示を消していません。" >&2
  exit 1
fi

CONTROL_OUTPUT="$(MUSIC_CONTROL_ACTION=playpause NAME=music.now MUSIC_PLAYER_STATE=playing bash "$MUSIC_SCRIPT" --env=localdev --dry-run)"
if ! grep -Fq "osascript music playpause" <<<"$CONTROL_OUTPUT" || ! grep -Fq "music.toggle" <<<"$CONTROL_OUTPUT"; then
  echo "Music の再生停止切り替えボタンが動作しません。" >&2
  exit 1
fi

echo "PASS: SketchyBar は中央に再生中の曲情報だけを表示できます。"
