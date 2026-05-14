#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="$ROOT_DIR/.config/amethyst/amethyst.yml"
LAYOUT_FILE="$ROOT_DIR/.config/amethyst/layouts/padded-fullscreen.js"

# 余白付きフルスクリーンは、Amethyst の通常レイアウト経路に乗せて Tall と同じ余白処理を受ける。
ruby -ryaml - "$CONFIG_FILE" "$LAYOUT_FILE" <<'RUBY'
config = YAML.load_file(ARGV.fetch(0))
layout_file = ARGV.fetch(1)

unless File.file?(layout_file)
  warn "余白付きフルスクリーンのカスタムレイアウトが見つかりません: #{layout_file}"
  exit 1
end

layout_source = File.read(layout_file)

required_snippets = [
  "function layout()",
  'name: "Padded Fullscreen"',
  "getFrameAssignments",
  "screenFrame",
  "windows.reduce"
]

missing_snippets = required_snippets.reject { |snippet| layout_source.include?(snippet) }
unless missing_snippets.empty?
  warn "余白付きフルスクリーンのレイアウト定義に必要な要素が不足しています: #{missing_snippets.join(', ')}"
  exit 1
end

if layout_source.match?(/window-margin-size|screen-padding/)
  warn "余白付きフルスクリーンは固定値を持たず、Amethyst の共通余白設定に追従してください。"
  exit 1
end

unless config["smart-window-margins"] == true
  warn "Tall 側の既存の余白設定を保つため、smart-window-margins は変更しないでください。"
  exit 1
end
RUBY

echo "PASS: Amethyst の余白付きフルスクリーンは Tall と同じ余白設定に追従します。"
