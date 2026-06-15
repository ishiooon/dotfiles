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
    script="$PLUGIN_DIR/codex_usage.sh"

sketchybar --add item clock right \
  --set clock \
    icon.drawing=off \
    update_freq=30 \
    script="$PLUGIN_DIR/clock.sh"

sketchybar --add bracket telemetry.status system.memory system.cpu codex.usage input.source clock \
  --set telemetry.status \
    background.color="$ACTIVE_BACKGROUND_COLOR" \
    background.corner_radius=8 \
    background.height=24
