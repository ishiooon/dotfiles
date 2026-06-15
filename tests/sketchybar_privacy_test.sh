#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.config/sketchybar/sketchybarrc"
INSTALL_SCRIPT="$ROOT_DIR/.bin/install-sketchybar.sh"
README_FILE="$ROOT_DIR/README.md"
PLUGIN_DIR="$ROOT_DIR/.config/sketchybar/plugins"

# 画面収録権限が必要になる alias 表示と、その展開入口を設定から取り除けているか確認する。
for file in "$CONFIG_FILE" "$INSTALL_SCRIPT" "$README_FILE"; do
  for forbidden in "menu.extras.toggle" "menu_extras_setup.sh" "menu_extras_toggle.sh" "--add alias" "default_menu_items" "•••" "Screen Recording" "画面収録" "alias 表示"; do
    if grep -Fq -- "$forbidden" "$file"; then
      echo "画面収録権限につながる不要な記述が残っています: $file: $forbidden" >&2
      exit 1
    fi
  done
done

# 不要になったプラグインファイルが残ると、後から誤って再接続されるため削除済みであることを確認する。
for removed_script in \
  "$PLUGIN_DIR/menu_extras_setup.sh" \
  "$PLUGIN_DIR/menu_extras_toggle.sh" \
  "$PLUGIN_DIR/front_app.sh" \
  "$PLUGIN_DIR/apple_menu_action.sh" \
  "$PLUGIN_DIR/menu_popup_hover.sh" \
  "$PLUGIN_DIR/restart_sketchybar.sh"; do
  if [[ -e "$removed_script" ]]; then
    echo "不要になった SketchyBar プラグインが残っています: $removed_script" >&2
    exit 1
  fi
done

echo "PASS: SketchyBar は画面収録権限が必要な追加アイコン展開機能を含みません。"
