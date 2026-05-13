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
CPU_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/cpu.sh"
MEMORY_SCRIPT="$ROOT_DIR/.config/sketchybar/plugins/memory.sh"

for expected in "system.cpu" "system.memory" "cpu.sh" "memory.sh"; do
  if ! grep -Fq "$expected" <<<"$CONFIG_TEXT"; then
    echo "SketchyBar の設定にCPUまたはメモリ表示の構成が不足しています: $expected" >&2
    exit 1
  fi
done

for script in "$CPU_SCRIPT" "$MEMORY_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "SketchyBar の使用率表示スクリプトが見つからないか、実行できません: $script" >&2
    exit 1
  fi
done

CPU_OUTPUT="$(NAME=system.cpu SKETCHYBAR_CPU_USAGE="sample" bash "$CPU_SCRIPT" --env=localdev --dry-run)"
MEMORY_OUTPUT="$(NAME=system.memory SKETCHYBAR_MEMORY_USAGE="sample" bash "$MEMORY_SCRIPT" --env=localdev --dry-run)"

if ! grep -Fq -- "--set system.cpu" <<<"$CPU_OUTPUT" || ! grep -Fq "label=sample" <<<"$CPU_OUTPUT"; then
  echo "CPU表示スクリプトがSketchyBar項目を更新していません。" >&2
  echo "$CPU_OUTPUT" >&2
  exit 1
fi

if ! grep -Fq -- "--set system.memory" <<<"$MEMORY_OUTPUT" || ! grep -Fq "label=sample" <<<"$MEMORY_OUTPUT"; then
  echo "メモリ表示スクリプトがSketchyBar項目を更新していません。" >&2
  echo "$MEMORY_OUTPUT" >&2
  exit 1
fi

for duplicated_label in "label=CPU" "label=MEM"; do
  if grep -Fq "$duplicated_label" <<<"$CPU_OUTPUT$MEMORY_OUTPUT"; then
    echo "CPUまたはメモリの種別名がアイコンとラベルで重複しています: $duplicated_label" >&2
    echo "$CPU_OUTPUT" >&2
    echo "$MEMORY_OUTPUT" >&2
    exit 1
  fi
done

echo "PASS: SketchyBar はCPUとメモリ使用率を可変値として表示できます。"
