#!/usr/bin/env bash
set -euo pipefail

readonly TAP_NAME="FelixKratz/formulae"
readonly PACKAGE_NAME="sketchybar"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly DOTFILES_CONFIG_DIR="$DOTFILES_DIR/.config/sketchybar"
readonly HOME_CONFIG_DIR="$HOME/.config/sketchybar"

DRY_RUN=false

main() {
  parse_arguments "$@"
  ensure_dotfiles_config_exists
  ensure_homebrew_available
  link_sketchybar_config
  install_sketchybar
  hide_native_menu_bar
  start_or_reload_sketchybar_service
  log_info "SketchyBar の導入手順が完了しました。"
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
  if [[ ! -f "$DOTFILES_CONFIG_DIR/sketchybarrc" ]]; then
    fail "SketchyBar の設定ファイルが見つかりません: $DOTFILES_CONFIG_DIR/sketchybarrc"
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

link_sketchybar_config() {
  run_command mkdir -p "$HOME/.config"

  if [[ -e "$HOME_CONFIG_DIR" && "$HOME_CONFIG_DIR" -ef "$DOTFILES_CONFIG_DIR" ]]; then
    log_info "SketchyBar の設定ディレクトリは既に dotfiles を参照しています。"
    return
  fi

  if [[ -e "$HOME_CONFIG_DIR" || -L "$HOME_CONFIG_DIR" ]]; then
    backup_existing_config
  fi

  # SketchyBar が起動時に読む場所へ dotfiles 配下の設定ディレクトリをリンクする。
  run_command ln -s "$DOTFILES_CONFIG_DIR" "$HOME_CONFIG_DIR"
}

install_sketchybar() {
  # 公式 tap を追加し、SketchyBar の実行ファイルと service 定義を導入する。
  run_command brew tap "$TAP_NAME"
  run_command brew install "$PACKAGE_NAME"
}

hide_native_menu_bar() {
  # 追加アプリアイコンが通常時に見えないよう、macOS 標準メニューバーを自動非表示にする。
  run_command defaults write NSGlobalDomain _HIHideMenuBar -bool true
  run_command defaults -currentHost write NSGlobalDomain _HIHideMenuBar -bool true
  run_command killall SystemUIServer
}

start_or_reload_sketchybar_service() {
  if [[ "$DRY_RUN" == "true" ]]; then
    run_command brew services start "$PACKAGE_NAME"
    run_command sketchybar --reload
    return
  fi

  if is_sketchybar_service_started; then
    # 既に起動している場合は停止を待たず、最新設定だけを読み込み直す。
    run_command sketchybar --reload
    return
  fi

  # ログイン時に自動起動し、初回起動時にも ~/.config/sketchybar/sketchybarrc を読み込ませる。
  run_command brew services start "$PACKAGE_NAME"
}

is_sketchybar_service_started() {
  brew services list 2>/dev/null | awk '$1 == "sketchybar" && $2 == "started" { found = 1 } END { exit found ? 0 : 1 }'
}

backup_existing_config() {
  local backup_dir
  backup_dir="$HOME/dotbackup/sketchybar-$(date +%Y%m%d_%H%M%S)"

  # 既存の手動設定を退避し、必要になったときに戻せる状態を保つ。
  run_command mkdir -p "$backup_dir"
  run_command mv "$HOME_CONFIG_DIR" "$backup_dir/sketchybar"
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
Usage: bash .bin/install-sketchybar.sh [--dry-run] [--env=localdev]

SketchyBar を Homebrew で導入し、dotfiles 管理の設定を読み込むようにします。
USAGE
}

log_info() {
  printf '[INFO] %s\n' "$1"
}

fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}

main "$@"
