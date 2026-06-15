#!/usr/bin/env bash

# 現在の入力ソースを短く表示し、日本語入力中かどうかを右側で判断できるようにする。
sketchybar --add item input.source right \
  --set input.source \
    icon.drawing=off \
    label="A" \
    label.padding_left=6 \
    label.padding_right=8 \
    update_freq=1 \
    script="$PLUGIN_DIR/input_source.sh" \
    background.drawing=off

# 左側に並ぶメニューだけを一つの背景にまとめ、入力状態は右側の状態表示へ分離する。
sketchybar --add bracket left.status apple.menu front.app \
  --set left.status \
    background.color="$ACTIVE_BACKGROUND_COLOR" \
    background.corner_radius=8 \
    background.height=24
