#!/usr/bin/env bash

# 右側は常時確認したい軽量な状態だけを一つのまとまりとして表示する。
sketchybar --add item system.memory right \
  --set system.memory \
    icon="MEM" \
    icon.color="$MUTED_TEXT_COLOR" \
    update_freq=10 \
    script="$PLUGIN_DIR/memory.sh"

sketchybar --add item system.cpu right \
  --set system.cpu \
    icon="CPU" \
    icon.color="$MUTED_TEXT_COLOR" \
    update_freq=5 \
    script="$PLUGIN_DIR/cpu.sh"

sketchybar --add item codex.usage right \
  --set codex.usage \
    icon="CX" \
    icon.color="$MUTED_TEXT_COLOR" \
    label="5h --" \
    update_freq=60 \
    script="$PLUGIN_DIR/codex_usage.sh" \
    popup.align=right \
    popup.y_offset=8 \
    popup.background.color="$BAR_COLOR" \
    popup.background.border_color="$BORDER_COLOR" \
    popup.background.border_width=1 \
    popup.background.corner_radius=8 \
  --subscribe codex.usage mouse.entered mouse.exited.global

sketchybar --add item codex.usage.five_hour popup.codex.usage \
  --set codex.usage.five_hour \
    icon.drawing=off \
    label="5h --"

sketchybar --add item codex.usage.weekly popup.codex.usage \
  --set codex.usage.weekly \
    icon.drawing=off \
    label="7d --"

for popup_item in codex.usage.five_hour codex.usage.weekly; do
  sketchybar --set "$popup_item" \
    background.drawing=off \
    script="$PLUGIN_DIR/menu_popup_hover.sh" \
    --subscribe "$popup_item" mouse.entered mouse.exited mouse.exited.global
done

sketchybar --add item clock right \
  --set clock \
    icon.drawing=off \
    update_freq=30 \
    script="$PLUGIN_DIR/clock.sh"

sketchybar --add bracket telemetry.status system.memory system.cpu codex.usage clock \
  --set telemetry.status \
    background.color="$ACTIVE_BACKGROUND_COLOR" \
    background.corner_radius=8 \
    background.height=24
