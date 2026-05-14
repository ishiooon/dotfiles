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

# 設定ファイルが存在しない場合は即時失敗し、配置漏れを検知する。
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Amethyst の設定ファイルが見つかりません: $CONFIG_FILE" >&2
  exit 1
fi

# YAML として読み込めること、かつデフォルト値を持つ設定項目が全て明示されていることを確認する。
ruby -ryaml - "$CONFIG_FILE" <<'RUBY'
config_file = ARGV.fetch(0)
config = YAML.load_file(config_file)

expected_keys = %w[
  layouts mod1 mod2
  cycle-layout cycle-layout-backward
  select-tall-layout select-wide-layout select-fullscreen-layout select-column-layout
  focus-screen-ccw focus-screen-cw focus-screen-1 focus-screen-2 focus-screen-3 focus-screen-4 focus-screen-5
  throw-screen-1 throw-screen-2 throw-screen-3 throw-screen-4 throw-screen-5
  shrink-main expand-main increase-main decrease-main
  focus-ccw focus-cw focus-main
  swap-screen-ccw swap-screen-cw swap-ccw swap-cw swap-main
  throw-space-1 throw-space-2 throw-space-3 throw-space-4 throw-space-5
  throw-space-6 throw-space-7 throw-space-8 throw-space-9 throw-space-10
  throw-space-left throw-space-right
  toggle-float toggle-tiling display-current-layout reevaluate-windows
  toggle-focus-follows-mouse relaunch-amethyst
  window-margins smart-window-margins window-margin-size window-max-count
  window-minimum-height window-minimum-width floating floating-is-blacklist
  ignore-menu-bar hide-menu-bar-icon float-small-windows mouse-follows-focus focus-follows-mouse
  mouse-swaps-windows mouse-resizes-windows enables-layout-hud enables-layout-hud-on-space-change
  use-canary-build new-windows-to-main follow-space-thrown-windows window-resize-step
  screen-padding-left screen-padding-right screen-padding-top screen-padding-bottom
  restore-layouts-on-launch debug-layout-info disable-padding-on-builtin-display
]

missing_keys = expected_keys - config.keys
unless missing_keys.empty?
  warn "デフォルト値を持つ設定項目が不足しています: #{missing_keys.join(', ')}"
  exit 1
end

unless config["layouts"].is_a?(Array) && config["layouts"].first == "bsp"
  warn "Amethyst の既定レイアウトとして bsp が先頭に設定されていません。"
  exit 1
end

unless config["layouts"].include?("padded-fullscreen")
  warn "余白付きフルスクリーン用のカスタムレイアウトが有効なレイアウト一覧に含まれていません。"
  exit 1
end

if config["layouts"].include?("fullscreen")
  warn "標準の fullscreen レイアウトは余白を消すため、有効なレイアウト一覧から外してください。"
  exit 1
end

unless config["select-fullscreen-layout"] == false
  warn "標準 fullscreen への直接ショートカットは無効化してください: #{config["select-fullscreen-layout"].inspect}"
  exit 1
end

custom_layout_shortcut = config["select-padded-fullscreen-layout"]
unless custom_layout_shortcut == { "mod" => "mod1", "key" => "d" }
  warn "余白付きフルスクリーンのショートカットが mod1+d に設定されていません: #{custom_layout_shortcut.inspect}"
  exit 1
end

command_keys = expected_keys.select { |key| config[key].is_a?(Hash) }
command_keys += %w[select-padded-fullscreen-layout]
invalid_commands = command_keys.reject { |key| config[key].key?("mod") && config[key].key?("key") }
unless invalid_commands.empty?
  warn "ショートカット設定に mod または key がありません: #{invalid_commands.join(', ')}"
  exit 1
end

# 余白の具体値は日々の好みで変わるため、型だけを確認して壊れた YAML を検知する。
expected_margin_types = {
  "window-margins" => [TrueClass, FalseClass],
  "smart-window-margins" => [TrueClass, FalseClass],
  "window-margin-size" => [Integer],
  "screen-padding-left" => [Integer],
  "screen-padding-right" => [Integer],
  "screen-padding-top" => [Integer],
  "screen-padding-bottom" => [Integer]
}

invalid_margin_types = expected_margin_types.reject { |key, types| types.any? { |type| config[key].is_a?(type) } }
unless invalid_margin_types.empty?
  details = invalid_margin_types.map { |key, types| "#{key}=#{config[key].inspect}, 期待する型=#{types.map(&:name).join('または')}" }
  warn "ウィンドウ間の隙間と画面外周の余白設定の型が期待と一致しません: #{details.join(', ')}"
  exit 1
end

active_key_counts = Hash.new(0)
File.readlines(config_file, chomp: true).each do |line|
  next if line.start_with?("#") || line.strip.empty? || line.start_with?(" ")

  key = line.split(":", 2).first
  active_key_counts[key] += 1 if expected_margin_types.key?(key)
end

duplicated_margin_keys = active_key_counts.select { |_key, count| count != 1 }
unless duplicated_margin_keys.empty?
  details = duplicated_margin_keys.map { |key, count| "#{key}=#{count}回" }
  warn "外周マージン設定の有効な定義回数が期待と一致しません: #{details.join(', ')}"
  exit 1
end
RUBY

# デフォルト値が無い項目はコメントアウトされた例として残し、意図せず有効化されないようにする。
for key in mod3 mod4 command1 command2 command3 command4 enable-tiling disable-tiling; do
  if ! grep -Eq "^# ${key}:" "$CONFIG_FILE"; then
    echo "デフォルト値が無い設定項目がコメントアウトされていません: $key" >&2
    exit 1
  fi
done

# 代表的な調整項目は、すぐ有効化できるコメント例として残す。
for pattern in "com.apple.systempreferences" "window-margin-size:" "screen-padding-top:"; do
  if ! grep -Fq "$pattern" "$CONFIG_FILE"; then
    echo "設定例のコメントが不足しています: $pattern" >&2
    exit 1
  fi
done

echo "PASS: Amethyst の設定ファイルはデフォルト項目を明示し、未定義項目をコメントアウトしています。"
