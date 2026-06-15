#!/usr/bin/env bash

# Apple の印は左端の目印として残し、マウス移動だけで別ウィンドウを出さない。
sketchybar --add item apple.menu left \
  --set apple.menu \
    icon="" \
    icon.font="SF Pro:Semibold:14.0" \
    icon.padding_left=5 \
    icon.padding_right=5 \
    label.drawing=off \
    padding_right=2 \
    background.drawing=off

# 前面アプリ名はアプリ切り替えイベントだけで更新し、hover popup は持たせない。
sketchybar --add item front.app left \
  --set front.app \
    icon.drawing=off \
    label="Finder" \
    label.padding_left=6 \
    label.padding_right=6 \
    script="$PLUGIN_DIR/current_app_menu.sh" \
    padding_left=1 \
    background.drawing=off \
  --subscribe front.app front_app_switched
