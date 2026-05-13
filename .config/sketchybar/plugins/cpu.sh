#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false

main() {
  parse_arguments "$@"

  local usage
  usage="${SKETCHYBAR_CPU_USAGE:-$(read_cpu_usage)}"

  # CPUの種別名はアイコンで表示しているため、ラベルには現在値だけを反映する。
  run_command sketchybar --set "$NAME" label="$usage"
}

parse_arguments() {
  while (($#)); do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        ;;
      --env=localdev)
        # テスト実行時に明示する環境指定。通常の表示更新には影響させない。
        ;;
      *)
        fail "未対応の引数です: $1"
        ;;
    esac
    shift
  done
}

read_cpu_usage() {
  local cpu_count
  cpu_count="$(sysctl -n hw.ncpu 2>/dev/null || printf '1')"

  ps -A -o %cpu= 2>/dev/null |
    awk -v cpu_count="$cpu_count" '
      { total += $1 }
      END {
        usage = cpu_count > 0 ? total / cpu_count : total
        if (usage > 100) usage = 100
        printf "%.0f%%", usage
      }
    '
}

run_command() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    return
  fi

  "$@"
}

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

main "$@"
