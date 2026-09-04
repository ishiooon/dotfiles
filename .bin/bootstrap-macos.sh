#!/usr/bin/env bash
set -euo pipefail
# 新しい macOS で dotfiles が管理する全構成を再現するための初期構成スクリプト。
readonly DEFAULT_REPOSITORY="https://github.com/ishiooon/dotfiles.git"
readonly DEFAULT_DIRECTORY="$HOME/dotfiles"
readonly FORMULAE=(neovim starship fzf ripgrep fd lazygit deno gh node php w3m coreutils)
readonly CASKS=(wezterm font-udev-gothic-nf)
DRY_RUN=false
REPOSITORY="$DEFAULT_REPOSITORY"
DOTFILES_DIR="$DEFAULT_DIRECTORY"
main() {
  parse_arguments "$@"
  ensure_macos
  ensure_required_commands
  ensure_homebrew
  prepare_dotfiles_repository
  install_packages
  install_php_debug_adapter
  install_dotfiles_configuration
  install_janky_borders
  install_neovim_plugins
  print_completion_message
}
parse_arguments() {
  while (($#)); do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        ;;
      --directory)
        shift
        DOTFILES_DIR="${1:-}"
        [[ -n "$DOTFILES_DIR" ]] || fail "--directory にはディレクトリを指定してください。"
        ;;
      --repository)
        shift
        REPOSITORY="${1:-}"
        [[ -n "$REPOSITORY" ]] || fail "--repository には Git リポジトリを指定してください。"
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
ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "このスクリプトは macOS でのみ実行できます。"
  fi
}
ensure_required_commands() {
  for command in git curl; do
    if ! command -v "$command" >/dev/null 2>&1; then
      fail "$command が見つかりません。macOS の Command Line Tools を導入してください。"
    fi
  done
}
ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    run_command /bin/bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'
    return
  fi
  log_info "Homebrew を導入します。管理者パスワードを求められる場合があります。"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew_from_standard_path
}
load_homebrew_from_standard_path() {
  local brew_path
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      return
    fi
  done
  fail "Homebrew の導入後に brew コマンドを見つけられませんでした。"
}
prepare_dotfiles_repository() {
  if [[ -e "$DOTFILES_DIR" || -L "$DOTFILES_DIR" ]]; then
    if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
      fail "既存のディレクトリが Git リポジトリではないため中断します: $DOTFILES_DIR"
    fi
    log_info "既存の dotfiles リポジトリを使用します: $DOTFILES_DIR"
    return
  fi
  run_command git clone "$REPOSITORY" "$DOTFILES_DIR"
}
install_packages() {
  # Homebrew の導入状態は保持し、必要な formula と cask の導入だけを行う。
  run_command brew install "${FORMULAE[@]}"
  run_command brew install --cask "${CASKS[@]}"
}
install_php_debug_adapter() {
  local debug_dir="$HOME/vscode-php-debug"
  if [[ -e "$debug_dir" || -L "$debug_dir" ]]; then
    [[ -d "$debug_dir/.git" ]] || fail "既存の PHP デバッグ拡張ディレクトリが Git リポジトリではありません: $debug_dir"
  else
    run_command git clone "https://github.com/xdebug/vscode-php-debug.git" "$debug_dir"
  fi
  run_command npm --prefix "$debug_dir" install
  run_command npm --prefix "$debug_dir" run build
}
install_janky_borders() {
  local install_script="$DOTFILES_DIR/.bin/install-janky-borders.sh"
  if [[ "$DRY_RUN" != "true" && ! -x "$install_script" ]]; then
    fail "JankyBorders のインストールスクリプトが見つかりません: $install_script"
  fi
  # bordersrc のリンク作成とサービス起動を既存の専用スクリプトへ委譲する。
  run_command bash "$install_script"
}
install_neovim_plugins() {
  # Neovim 起動時の lazy.nvim 同期を先に実行し、管理対象プラグインを初回から利用可能にする。
  run_command nvim --headless '+Lazy! sync' '+qa'
}
install_dotfiles_configuration() {
  local install_script="$DOTFILES_DIR/.bin/install.sh"
  if [[ "$DRY_RUN" != "true" && ! -x "$install_script" ]]; then
    fail "dotfiles のインストールスクリプトが見つからないか、実行権限がありません: $install_script"
  fi
  # dotfiles の設定を HOME へリンクし、WezTerm が ~/.config/wezterm を読み込める状態にする。
  export DOTFILES_INSTALL_ROOT="$DOTFILES_DIR"
  run_command bash "$install_script"
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
Usage: bash .bin/bootstrap-macos.sh [--dry-run] [--directory PATH] [--repository URL] [--env=localdev]
新しい macOS にシェル、Neovim、Starship、WezTerm、JankyBorders、Codex の管理対象設定と関連ツールを導入します。
既存の Git リポジトリは上書きせず、そのまま利用します。
USAGE
}
print_completion_message() {
  log_info "macOS の初期構成が完了しました。"
  log_info "シェル、Neovim、Starship、WezTerm、JankyBorders の設定を利用できます。"
  log_info "API キーが必要な場合は ~/.zsh/env.local.zsh を確認してください。"
}
log_info() {
  printf '[INFO] %s\n' "$1"
}
fail() {
  printf '[ERROR] %s\n' "$1" >&2
  exit 1
}
main "$@"
