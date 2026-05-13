#!/usr/bin/env bash
set -euo pipefail

CURRENT_TIME="$(date '+%m/%d %H:%M')"

# 時計は一定間隔で再描画されるため、現在時刻を短く表示する。
sketchybar --set "$NAME" label="$CURRENT_TIME"
