#!/usr/bin/env bash

# macOS 標準の Apple メニューに近い入口を、バーの一番左へ配置する。
sketchybar --add item apple.menu left \
  --set apple.menu \
    icon="" \
    icon.font="SF Pro:Semibold:14.0" \
    icon.padding_left=8 \
    icon.padding_right=8 \
    label.drawing=off \
    script="$PLUGIN_DIR/apple_menu_action.sh" \
    padding_right=5 \
    background.drawing=on \
    background.color="$ACTIVE_BACKGROUND_COLOR" \
    background.corner_radius=6 \
    background.height=24 \
    background.padding_left=3 \
    background.padding_right=3 \
    popup.align=left \
    popup.y_offset=8 \
    popup.background.color="$BAR_COLOR" \
    popup.background.border_color="$BORDER_COLOR" \
    popup.background.border_width=1 \
    popup.background.corner_radius=8 \
  --subscribe apple.menu mouse.entered mouse.exited.global

sketchybar --add item apple.menu.about_this_mac popup.apple.menu \
  --set apple.menu.about_this_mac \
    icon.drawing=off \
    label="About This Mac" \
    click_script="APPLE_MENU_ACTION=about_this_mac $PLUGIN_DIR/apple_menu_action.sh; sketchybar --set apple.menu popup.drawing=off"

sketchybar --add item apple.menu.system_settings popup.apple.menu \
  --set apple.menu.system_settings \
    icon.drawing=off \
    label="System Settings..." \
    click_script="APPLE_MENU_ACTION=system_settings $PLUGIN_DIR/apple_menu_action.sh; sketchybar --set apple.menu popup.drawing=off"

sketchybar --add item apple.menu.app_store popup.apple.menu \
  --set apple.menu.app_store \
    icon.drawing=off \
    label="App Store..." \
    click_script="APPLE_MENU_ACTION=app_store $PLUGIN_DIR/apple_menu_action.sh; sketchybar --set apple.menu popup.drawing=off"

sketchybar --add item apple.menu.force_quit popup.apple.menu \
  --set apple.menu.force_quit \
    icon.drawing=off \
    label="Force Quit..." \
    click_script="APPLE_MENU_ACTION=force_quit $PLUGIN_DIR/apple_menu_action.sh; sketchybar --set apple.menu popup.drawing=off"

sketchybar --add item apple.menu.sleep popup.apple.menu \
  --set apple.menu.sleep \
    icon.drawing=off \
    label="Sleep" \
    click_script="APPLE_MENU_ACTION=sleep $PLUGIN_DIR/apple_menu_action.sh; sketchybar --set apple.menu popup.drawing=off"

sketchybar --add item apple.menu.lock_screen popup.apple.menu \
  --set apple.menu.lock_screen \
    icon.drawing=off \
    label="Lock Screen" \
    click_script="APPLE_MENU_ACTION=lock_screen $PLUGIN_DIR/apple_menu_action.sh; sketchybar --set apple.menu popup.drawing=off"

sketchybar --add item apple.menu.restart_sketchybar popup.apple.menu \
  --set apple.menu.restart_sketchybar \
    icon.drawing=off \
    label="Restart SketchyBar" \
    click_script="$PLUGIN_DIR/restart_sketchybar.sh; sketchybar --set apple.menu popup.drawing=off"

# 前面アプリ名はクリックではなくホバーで、そのアプリの基本メニューを表示する。
sketchybar --add item front.app left \
  --set front.app \
    icon.drawing=off \
    label="Finder" \
    label.padding_left=8 \
    label.padding_right=8 \
    script="$PLUGIN_DIR/current_app_menu.sh" \
    padding_left=3 \
    background.drawing=on \
    background.color="$ACTIVE_BACKGROUND_COLOR" \
    background.corner_radius=6 \
    background.height=24 \
    popup.align=left \
    popup.y_offset=8 \
    popup.background.color="$BAR_COLOR" \
    popup.background.border_color="$BORDER_COLOR" \
    popup.background.border_width=1 \
    popup.background.corner_radius=8 \
  --subscribe front.app front_app_switched mouse.entered mouse.exited.global

sketchybar --add item current.app.about popup.front.app \
  --set current.app.about \
    icon.drawing=off \
    label="About Finder" \
    click_script="CURRENT_APP_ACTION=about $PLUGIN_DIR/current_app_menu.sh; sketchybar --set front.app popup.drawing=off"

sketchybar --add item current.app.settings popup.front.app \
  --set current.app.settings \
    icon.drawing=off \
    label="Settings..." \
    click_script="CURRENT_APP_ACTION=settings $PLUGIN_DIR/current_app_menu.sh; sketchybar --set front.app popup.drawing=off"

sketchybar --add item current.app.hide popup.front.app \
  --set current.app.hide \
    icon.drawing=off \
    label="Hide Finder" \
    click_script="CURRENT_APP_ACTION=hide $PLUGIN_DIR/current_app_menu.sh; sketchybar --set front.app popup.drawing=off"

sketchybar --add item current.app.hide_others popup.front.app \
  --set current.app.hide_others \
    icon.drawing=off \
    label="Hide Others" \
    click_script="CURRENT_APP_ACTION=hide_others $PLUGIN_DIR/current_app_menu.sh; sketchybar --set front.app popup.drawing=off"

sketchybar --add item current.app.show_all popup.front.app \
  --set current.app.show_all \
    icon.drawing=off \
    label="Show All" \
    click_script="CURRENT_APP_ACTION=show_all $PLUGIN_DIR/current_app_menu.sh; sketchybar --set front.app popup.drawing=off"

sketchybar --add item current.app.quit popup.front.app \
  --set current.app.quit \
    icon.drawing=off \
    label="Quit Finder" \
    click_script="CURRENT_APP_ACTION=quit $PLUGIN_DIR/current_app_menu.sh; sketchybar --set front.app popup.drawing=off"

# popup 内に入った後は項目側のイベントで表示を維持し、popup 領域から離れたときだけ閉じる。
for popup_item in \
  apple.menu.about_this_mac \
  apple.menu.system_settings \
  apple.menu.app_store \
  apple.menu.force_quit \
  apple.menu.sleep \
  apple.menu.lock_screen \
  apple.menu.restart_sketchybar \
  current.app.about \
  current.app.settings \
  current.app.hide \
  current.app.hide_others \
  current.app.show_all \
  current.app.quit; do
  sketchybar --set "$popup_item" \
    background.drawing=off \
    script="$PLUGIN_DIR/menu_popup_hover.sh" \
    --subscribe "$popup_item" mouse.entered mouse.exited mouse.exited.global
done
