#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AMETHYST_CONFIG="$ROOT_DIR/.config/amethyst/amethyst.yml"
SKETCHYBAR_CONFIG="$ROOT_DIR/.config/sketchybar/sketchybarrc"

if [[ ! -f "$AMETHYST_CONFIG" || ! -f "$SKETCHYBAR_CONFIG" ]]; then
  echo "Amethyst または SketchyBar の設定ファイルが見つかりません。" >&2
  exit 1
fi

# SketchyBar のバーが占有する高さを Amethyst の上余白に反映し、ウィンドウへの重なりを防ぐ。
ruby -ryaml - "$AMETHYST_CONFIG" "$SKETCHYBAR_CONFIG" <<'RUBY'
amethyst_config = YAML.load_file(ARGV.fetch(0))
sketchybar_config = File.read(ARGV.fetch(1))

def read_bar_integer(config_text, key)
  match = config_text.match(/^\s*#{Regexp.escape(key)}=(\d+)\s*$/)
  unless match
    warn "SketchyBar のバー設定が見つかりません: #{key}"
    exit 1
  end
  match[1].to_i
end

bar_height = read_bar_integer(sketchybar_config, "height")
bar_y_offset = read_bar_integer(sketchybar_config, "y_offset")

minimum_top_padding = bar_y_offset + bar_height
unless amethyst_config["screen-padding-top"] >= minimum_top_padding
  warn "Amethyst の上余白が SketchyBar の占有領域を避けていません: screen-padding-top=#{amethyst_config["screen-padding-top"]}, 必要最小値=#{minimum_top_padding}"
  exit 1
end

edge_padding_keys = %w[screen-padding-left screen-padding-right screen-padding-bottom window-margin-size]
negative_values = edge_padding_keys.select { |key| amethyst_config[key].to_i.negative? }
unless negative_values.empty?
  warn "Amethyst の余白に負の値が含まれています: #{negative_values.join(', ')}"
  exit 1
end
RUBY

echo "PASS: Amethyst は SketchyBar の占有領域を避け、余白に安全な値を使っています。"
