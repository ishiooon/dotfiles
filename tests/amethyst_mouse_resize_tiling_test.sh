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

# マウスでサイズ変更した結果をレイアウトへ反映し、フローティング状態の変更は明示したショートカットだけで行う。
ruby -ryaml - "$CONFIG_FILE" <<'RUBY'
config_file = ARGV.fetch(0)
config = YAML.load_file(config_file)

expected_values = {
  "floating" => [],
  "floating-is-blacklist" => true,
  "float-small-windows" => false,
  "mouse-swaps-windows" => false,
  "mouse-resizes-windows" => true
}

invalid_values = expected_values.reject { |key, value| config[key] == value }
unless invalid_values.empty?
  details = invalid_values.map { |key, value| "#{key}=#{config[key].inspect}, 期待値=#{value.inspect}" }
  warn "マウスリサイズをレイアウトへ反映しつつ、フローティング状態を自動変更しない設定が期待と一致しません: #{details.join(', ')}"
  exit 1
end

toggle_float = config["toggle-float"]
unless toggle_float == { "mod" => "mod1", "key" => "t" }
  warn "フローティング切り替えのショートカットが期待と一致しません: #{toggle_float.inspect}"
  exit 1
end

toggle_focus_follows_mouse = config["toggle-focus-follows-mouse"]
unless toggle_focus_follows_mouse == { "mod" => "mod2", "key" => "x" }
  warn "マウスポインター追従フォーカスの切り替えショートカットが期待と一致しません: #{toggle_focus_follows_mouse.inspect}"
  exit 1
end
RUBY

echo "PASS: Amethyst はマウスリサイズをレイアウトへ反映し、フローティング切り替えを mod1+t に限定する設定です。"
