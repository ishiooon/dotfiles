#!/usr/bin/env bash
set -euo pipefail

PLUGIN_SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${CONFIG_DIR:-$(cd "$PLUGIN_SELF_DIR/.." && pwd)}"
source "$CONFIG_DIR/plugins/lib.sh"

main() {
  parse_arguments "$@"

  local source_name
  local label
  source_name="$(read_input_source_name)"
  label="$(input_source_label "$source_name")"

  # macOS の入力ソース情報を読み取り、SketchyBar の入力状態項目へ反映する。
  run_command sketchybar --set "${NAME:-input.source}" label="$label"
}

parse_arguments() {
  while (($#)); do
    if parse_common_argument "$1"; then
      shift
      continue
    fi

    fail "未対応の引数です: $1"
  done
}

read_input_source_name() {
  if [[ -n "${SKETCHYBAR_INPUT_SOURCE_NAME:-}" ]]; then
    printf '%s\n' "$SKETCHYBAR_INPUT_SOURCE_NAME"
    return
  fi

  read_macos_input_source_name
}

input_source_label() {
  local source_name="$1"

  if is_japanese_input_source "$source_name"; then
    printf 'あ\n'
    return
  fi

  printf 'A\n'
}

is_japanese_input_source() {
  local source_name="$1"
  local normalized_name
  normalized_name="$(printf '%s' "$source_name" | tr '[:upper:]' '[:lower:]')"

  case "$normalized_name" in
    *japanese* | *kotoeri* | *hiragana* | *katakana* | *romajityping* | *日本語* | *かな*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

read_macos_input_source_name() {
  local plist_path="$HOME/Library/Preferences/com.apple.HIToolbox.plist"

  if [[ ! -f "$plist_path" ]]; then
    printf 'ABC\n'
    return
  fi

  /usr/libexec/PlistBuddy -c 'Print :AppleSelectedInputSources' "$plist_path" 2>/dev/null |
    awk -F ' = ' '
      /Input Mode =/ {
        source_name = $2
      }
      /KeyboardLayout Name =/ {
        source_name = $2
      }
      /Bundle ID =/ {
        fallback_name = $2
      }
      END {
        if (source_name != "") {
          print source_name
          exit
        }
        if (fallback_name != "") {
          print fallback_name
          exit
        }
        print "ABC"
      }
    '
}

main "$@"
