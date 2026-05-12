#!/usr/bin/env bash
set -euo pipefail

readonly TAP_NAME="FelixKratz/formulae"
readonly PACKAGE_NAME="borders"
readonly SERVICE_NAME="borders"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly DOTFILES_CONFIG_FILE="$DOTFILES_DIR/.config/borders/bordersrc"
readonly HOME_CONFIG_FILE="$HOME/.config/borders/bordersrc"

DRY_RUN=false

main() {
  parse_arguments "$@"
  ensure_dotfiles_config_exists
  ensure_homebrew_available
  link_borders_config
  install_janky_borders
  start_janky_borders_service
  print_completion_message
}

parse_arguments() {
  while (($#)); do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        ;;
      --env=localdev)
        # テスト実行時に明示する環境指定。通常の導入処理には影響させない。
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        fail "未対応の引数です: $1"
        ;;
    esac
    shift
  done
}

ensure_dotfiles_config_exists() {
  if [[ ! -f "$DOTFILES_CONFIG_FILE" ]]; then
    fail "JankyBorders の設定ファイルが見つかりません: $DOTFILES_CONFIG_FILE"
  fi
}

ensure_homebrew_available() {
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "ドライランのため Homebrew の存在確認を省略します。"
    return
  fi

  if ! command -v brew >/dev/null 2>&1; then
    fail "Homebrew が見つかりません。先に Homebrew をインストールしてください。"
  fi
}

link_borders_config() {
  local config_dir
  config_dir="$(dirname "$HOME_CONFIG_FILE")"

  run_command mkdir -p "$config_dir"

  if [[ -e "$HOME_CONFIG_FILE" && "$HOME_CONFIG_FILE" -ef "$DOTFILES_CONFIG_FILE" ]]; then
    log_info "JankyBorders の設定ファイルは既に dotfiles を参照しています。"
    return
  fi

  if [[ -e "$HOME_CONFIG_FILE" || -L "$HOME_CONFIG_FILE" ]]; then
    backup_existing_config
  fi

  # Homebrew service が起動時に読む場所へ dotfiles 配下の設定をリンクする。
  run_command ln -s "$DOTFILES_CONFIG_FILE" "$HOME_CONFIG_FILE"
}

install_janky_borders() {
  # 公式 tap を追加し、JankyBorders の実行ファイルである borders を導入する。
  run_command brew tap "$TAP_NAME"
  run_command brew install "$PACKAGE_NAME"
}

start_janky_borders_service() {
  # ログイン時に自動起動し、~/.config/borders/bordersrc を読み込む状態にする。
  run_command brew services start "$SERVICE_NAME"
}

backup_existing_config() {
  local backup_dir
  backup_dir="$HOME/dotbackup/janky-borders-$(date +%Y%m%d_%H%M%S)"

  # 既存の手動設定を退避し、必要になったときに戻せる状態を保つ。
  run_command mkdir -p "$backup_dir"
  run_command mv "$HOME_CONFIG_FILE" "$backup_dir/bordersrc"
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

print_usage() {
  cat <<'USAGE'
Usage: bash .bin/install-janky-borders.sh [--dry-run] [--env=localdev]

JankyBorders を Homebrew で導入し、dotfiles 管理の bordersrc を読み込むようにします。
USAGE
}

print_completion_message() {
  log_info "JankyBorders の導入手順が完了しました。"
  log_info "設定変更後は ~/.config/borders/bordersrc を編集し、brew services restart borders で再読み込みしてください。"
}

log_info() {
  printf '[INFO] %s\n' "$1"
}

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

main "$@"
