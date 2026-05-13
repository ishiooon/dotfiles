#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/plugins/lib.sh"

main() {
  parse_arguments "$@"

  # reload では古い item が残る場合があるため、LaunchAgent に新しいプロセスを起動し直させる。
  run_command killall sketchybar
}

parse_arguments() {
  while (($#)); do
    parse_common_argument "$1" || fail "未対応の引数です: $1"
    shift
  done
}

main "$@"
