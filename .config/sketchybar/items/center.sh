#!/usr/bin/env bash

# 中央は現在の再生曲だけを表示し、視覚化は加えずに軽く保つ。
sketchybar --add item music.toggle center \
  --set music.toggle \
    icon="▶" \
    icon.color="$TEXT_COLOR" \
    label.drawing=off \
    click_script="MUSIC_CONTROL_ACTION=playpause NAME=music.now $PLUGIN_DIR/music_now_playing.sh" \
    background.drawing=off

sketchybar --add item music.now center \
  --set music.now \
    icon.drawing=off \
    label="Not Playing" \
    label.max_chars=32 \
    scroll_texts=on \
    update_freq=8 \
    script="$PLUGIN_DIR/music_now_playing.sh" \
    click_script="open -a Music" \
    background.drawing=off \
    popup.align=center \
    popup.y_offset=8 \
    popup.background.color="$BAR_COLOR" \
    popup.background.border_color="$BORDER_COLOR" \
    popup.background.border_width=1 \
    popup.background.corner_radius=8 \
  --subscribe music.now mouse.entered mouse.exited.global

sketchybar --add item music.playlist.title popup.music.now \
  --set music.playlist.title \
    icon.drawing=off \
    label="Playlist"

for queue_index in 1 2 3 4 5; do
  sketchybar --add item "music.queue.$queue_index" popup.music.now \
    --set "music.queue.$queue_index" \
      icon.drawing=off \
      drawing=off \
      label=""
done

for popup_item in music.playlist.title music.queue.1 music.queue.2 music.queue.3 music.queue.4 music.queue.5; do
  sketchybar --set "$popup_item" \
    background.drawing=off \
    script="$PLUGIN_DIR/menu_popup_hover.sh" \
    --subscribe "$popup_item" mouse.entered mouse.exited mouse.exited.global
done

sketchybar --add bracket music.status music.toggle music.now \
  --set music.status \
    background.color="$ACTIVE_BACKGROUND_COLOR" \
    background.corner_radius=8 \
    background.height=24
