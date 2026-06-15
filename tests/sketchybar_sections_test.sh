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
CONFIG_TEXT="$(find "$ROOT_DIR/.config/sketchybar" -maxdepth 2 -type f \( -name '*.sh' -o -name 'sketchybarrc' \) -print0 | xargs -0 cat)"
LEFT_ITEMS_FILE="$ROOT_DIR/.config/sketchybar/items/left.sh"
APPLE_MENU_BLOCK="$(awk '/--add item apple.menu left/{capture=1} capture && /--add item front.app left/{capture=0} capture{print}' "$LEFT_ITEMS_FILE")"
FRONT_APP_BLOCK="$(awk '/--add item front.app left/{capture=1} capture{print} /--subscribe front.app/{capture=0}' "$LEFT_ITEMS_FILE")"
MOCK_DIR="$(mktemp -d)"
OUTPUT_FILE="$MOCK_DIR/sketchybar.commands"

# テスト用の sketchybar コマンドを用意し、実際のバーへ設定を書き込まずに起動時の指定を確認する。
trap 'rm -rf "$MOCK_DIR"' EXIT
cat >"$MOCK_DIR/sketchybar" <<'MOCK'
#!/usr/bin/env bash
printf 'sketchybar' >>"$SKETCHYBAR_COMMAND_LOG"
printf ' %q' "$@" >>"$SKETCHYBAR_COMMAND_LOG"
printf '\n' >>"$SKETCHYBAR_COMMAND_LOG"
MOCK
chmod +x "$MOCK_DIR/sketchybar"

SKETCHYBAR_COMMAND_LOG="$OUTPUT_FILE" CONFIG_DIR="$ROOT_DIR/.config/sketchybar" PATH="$MOCK_DIR:$PATH" bash "$CONFIG_FILE"
BAR_COMMAND="$(grep -m 1 -F "sketchybar --bar " "$OUTPUT_FILE")"
LEFT_STATUS_COMMAND="$(grep -m 1 -F -- "--add bracket left.status" "$OUTPUT_FILE")"
MUSIC_STATUS_COMMAND="$(grep -m 1 -F -- "--add bracket music.status" "$OUTPUT_FILE")"
TELEMETRY_STATUS_COMMAND="$(grep -m 1 -F -- "--add bracket telemetry.status" "$OUTPUT_FILE")"

# 左端の Apple 表示と前面アプリ名は残し、マウス移動だけで別ウィンドウを出さない。
for expected in "apple.menu" "front.app" "current_app_menu.sh"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "左側の基本表示に必要な構成が不足しています: $expected" >&2
    exit 1
  fi
done

for forbidden in "popup." "mouse.entered" "mouse.exited" "popup.drawing=on" "menu_popup_hover.sh" "apple_menu_action.sh" "restart_sketchybar.sh"; do
  if grep -Fq "$forbidden" <<<"$CONFIG_TEXT"; then
    echo "上部バーのホバー popup 構成が残っています: $forbidden" >&2
    exit 1
  fi
done

if grep -Fq -- "--subscribe apple.menu" <<<"$APPLE_MENU_BLOCK"; then
  echo "Apple 表示がマウスイベントを購読しています。" >&2
  exit 1
fi

if ! grep -Fq -- "--subscribe front.app front_app_switched" <<<"$FRONT_APP_BLOCK"; then
  echo "前面アプリ名がアプリ切り替えイベントだけを購読していません。" >&2
  exit 1
fi

if ! grep -Fq "icon.drawing=off" <<<"$FRONT_APP_BLOCK" || grep -Fq 'icon="◆"' <<<"$FRONT_APP_BLOCK"; then
  echo "前面アプリ名の左に不要なダイヤアイコンが残っています。" >&2
  exit 1
fi

if ! grep -Fq "padding_right=" <<<"$APPLE_MENU_BLOCK"; then
  echo "Apple アイコンと前面アプリ名の間に必要な余白が不足しています。" >&2
  exit 1
fi

for expected in "icon.padding_left=5" "icon.padding_right=5" "padding_right=2"; do
  if ! grep -Fq "$expected" <<<"$APPLE_MENU_BLOCK"; then
    echo "左側 Apple メニューの余白が大きすぎます: $expected" >&2
    exit 1
  fi
done

for expected in "label.padding_left=6" "label.padding_right=6" "padding_left=1"; do
  if ! grep -Fq "$expected" <<<"$FRONT_APP_BLOCK"; then
    echo "左側の前面アプリ表示の余白が大きすぎます: $expected" >&2
    exit 1
  fi
done

# 左側 island の背景は bracket が一度だけ描き、親項目側では背景を重ねない。
if grep -Fq "background.drawing=on" <<<"$APPLE_MENU_BLOCK$FRONT_APP_BLOCK"; then
  echo "左側の親項目が個別背景を描いており、左側 island の背景と重なっています。" >&2
  exit 1
fi

for stale_item in "apple.menu.about_this_mac" "current.app.quit" "music.queue.5" "codex.usage.weekly"; do
  if ! grep -Fq "$stale_item" "$CONFIG_FILE"; then
    echo "削除した popup item を再読み込み前に掃除していません: $stale_item" >&2
    exit 1
  fi
done

if grep -Fq "popup.drawing=toggle" <<<"$CONFIG_TEXT"; then
  echo "popup をクリックで開閉する古い設定が残っています。" >&2
  exit 1
fi

for expected in "color=0x00000000" "border_width=0" "shadow=off" "y_offset=0"; do
  if ! grep -Fq "$expected" <<<"$BAR_COMMAND"; then
    echo "空白部分へ背景を描かないためのバー設定が不足しています: $expected" >&2
    echo "$BAR_COMMAND" >&2
    exit 1
  fi
done

for command in "$LEFT_STATUS_COMMAND" "$MUSIC_STATUS_COMMAND" "$TELEMETRY_STATUS_COMMAND"; do
  if ! grep -Fq "background.color=0x33d4be98" <<<"$command"; then
    echo "island が薄い背景色を使っていません。" >&2
    echo "$command" >&2
    exit 1
  fi
done

for expected in "--add item input.source right" "--add bracket left.status apple.menu front.app" "input_source.sh"; do
  if ! grep -Fq -- "$expected" "$OUTPUT_FILE"; then
    echo "入力状態表示を右側へ分離する構成が不足しています: $expected" >&2
    exit 1
  fi
done

for expected in "--add bracket telemetry.status system.memory system.cpu codex.usage input.source clock" "system.memory" "system.cpu" "codex.usage" "clock"; do
  if ! grep -Fq -- "$expected" <<<"$CONFIG_TEXT"; then
    echo "右側の telemetry island に必要な構成が不足しています: $expected" >&2
    exit 1
  fi
done

echo "PASS: SketchyBar は hover popup を持たず、左側表示と telemetry island を保っています。"
