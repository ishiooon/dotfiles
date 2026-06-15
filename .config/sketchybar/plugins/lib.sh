#!/usr/bin/env bash

# 各プラグインの dry-run 出力を揃え、テストで SketchyBar へ実際に書き込まないようにする。
DRY_RUN="${DRY_RUN:-false}"

parse_common_argument() {
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --env=localdev)
      # テスト実行時に明示する環境指定。通常の表示更新には影響させない。
      ;;
    *)
      return 1
      ;;
  esac
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
