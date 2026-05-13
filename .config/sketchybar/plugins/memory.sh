#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false

main() {
  parse_arguments "$@"

  local usage
  usage="${SKETCHYBAR_MEMORY_USAGE:-$(read_memory_usage)}"

  # メモリの種別名はアイコンで表示しているため、ラベルには現在値だけを反映する。
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

read_memory_usage() {
  local total_memory
  total_memory="$(sysctl -n hw.memsize 2>/dev/null || printf '0')"

  vm_stat 2>/dev/null |
    awk -v total_memory="$total_memory" '
      /page size of/ {
        page_size = $8
      }
      /Pages active/ || /Pages wired down/ || /Pages occupied by compressor/ {
        gsub(/\./, "", $NF)
        used_pages += $NF
      }
      END {
        if (total_memory <= 0 || page_size <= 0) {
          printf "--"
          exit
        }
        printf "%.0f%%", used_pages * page_size * 100 / total_memory
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
