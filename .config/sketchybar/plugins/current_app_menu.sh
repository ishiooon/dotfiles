#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"

main() {
  parse_arguments "$@"
  update_current_app_label "$(read_frontmost_app_name)"
}

parse_arguments() {
  while (($#)); do
    parse_common_argument "$1" || fail "未対応の引数です: $1"
    shift
  done
}

read_frontmost_app_name() {
  if [[ -n "${INFO:-}" ]]; then
    printf '%s\n' "$INFO"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'Finder\n'
    return
  fi

  osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || printf 'Finder\n'
}

update_current_app_label() {
  local app_name="$1"

  # 前面アプリ名を SketchyBar の左側表示へ反映する。
  run_command sketchybar --set "${NAME:-front.app}" label="$app_name"
}

main "$@"
