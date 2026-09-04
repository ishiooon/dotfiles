#!/usr/bin/env bash
set -Eeuo pipefail
# 新しい macOS で dotfiles が管理する全構成を安全に再現する初期構成スクリプト。
readonly DEFAULT_REPOSITORY="https://github.com/ishiooon/dotfiles.git"
readonly DEFAULT_DIRECTORY="$HOME/dotfiles"
readonly FORMULAE=(neovim starship fzf ripgrep fd lazygit deno gh node php w3m coreutils)
readonly CASKS=(wezterm font-udev-gothic-nf)
readonly MANAGED_HOME_PATHS=(
  "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash" "$HOME/.zsh" "$HOME/.config"
  "$HOME/.bin" "$HOME/.claude" "$HOME/.agents" "$HOME/.codex/AGENTS.md"
  "$HOME/.codex/agents" "$HOME/.mcp.json" "$HOME/.local/share/nvim"
  "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
)
DRY_RUN=false
REPOSITORY="$DEFAULT_REPOSITORY"
DOTFILES_DIR="$DEFAULT_DIRECTORY"
CURRENT_STEP=""
ROLLBACK_DIR=""
ROLLBACK_ACTIVE=false
SNAPSHOT_READY=false
DOTFILES_CREATED=false
PHP_DEBUG_CREATED=false
HOMEBREW_CREATED=false
CODEX_DIRECTORY_EXISTED=false
BORDERS_PREEXISTING=false
declare -a COMPLETED_STEPS=()
declare -a SKIPPED_ITEMS=()
declare -a MISSING_ITEMS=()
declare -a WARNING_ITEMS=()
declare -a FAILURE_ITEMS=()
declare -a MISSING_FORMULAE=()
declare -a MISSING_CASKS=()
declare -a SNAPSHOT_PATHS=()
declare -a SNAPSHOT_BACKUPS=()
main() {
  trap 'handle_failure "$?" "$LINENO"' ERR
  parse_arguments "$@"
  run_step "macOS 環境の確認" ensure_macos
  run_step "基本コマンドの確認" ensure_required_commands
  run_step "Homebrew の準備" ensure_homebrew
  run_step "dotfiles リポジトリの準備" prepare_dotfiles_repository
  run_step "既存設定の退避" prepare_rollback_snapshot
  run_step "Homebrew パッケージの準備" install_packages
  run_step "PHP デバッグ拡張の準備" install_php_debug_adapter
  run_step "dotfiles 設定のリンク" install_dotfiles_configuration
  run_step "JankyBorders の準備" install_janky_borders
  run_step "Neovim プラグインの同期" install_neovim_plugins
  print_completion_message
  print_summary "成功"
}
parse_arguments() {
  while (($#)); do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
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
      --env=localdev) ;;
      -h|--help) print_usage; exit 0 ;;
      *) fail "未対応の引数です: $1" ;;
    esac
    shift
  done
}
run_step() {
  CURRENT_STEP="$1"
  shift
  log_info "[開始] $CURRENT_STEP"
  "$@"
  COMPLETED_STEPS+=("$CURRENT_STEP")
  log_info "[完了] $CURRENT_STEP"
  CURRENT_STEP=""
}
ensure_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || fail "このスクリプトは macOS でのみ実行できます。"
}
ensure_required_commands() {
  local command
  for command in git curl; do
    command -v "$command" >/dev/null 2>&1 || fail "$command が見つかりません。Command Line Tools を導入してください。"
  done
}
ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    SKIPPED_ITEMS+=("Homebrew は導入済みです。")
    log_info "[スキップ] Homebrew は導入済みです。"
    return
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    MISSING_ITEMS+=("Homebrew")
    log_info "[不足] Homebrew（ドライランでは導入しません。）"
    run_command /bin/bash -c 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'
    return
  fi
  log_info "管理者パスワードを求められる場合があります。"
  log_info "[実行] Homebrew 公式インストールスクリプト"
  HOMEBREW_CREATED=true
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
    [[ -d "$DOTFILES_DIR/.git" ]] || fail "既存のディレクトリが Git リポジトリではありません: $DOTFILES_DIR"
    SKIPPED_ITEMS+=("dotfiles リポジトリは既存のものを使用します。")
    log_info "[スキップ] 既存の dotfiles リポジトリを使用します。"
    return
  fi
  DOTFILES_CREATED=true
  run_command git clone "$REPOSITORY" "$DOTFILES_DIR"
}
prepare_rollback_snapshot() {
  [[ "$DRY_RUN" == "true" ]] && { log_info "[予定] ドライランのため既存設定は変更しません。"; return; }
  local backup_dir="$HOME/dotbackup/bootstrap-macos-$(date +%Y%m%d_%H%M%S)"
  run_command mkdir -p "$backup_dir/originals"
  ROLLBACK_DIR="$backup_dir"
  [[ -d "$HOME/.codex" ]] && CODEX_DIRECTORY_EXISTED=true
  local path
  for path in "${MANAGED_HOME_PATHS[@]}" "$DOTFILES_DIR/.bash/env.local.bash" "$DOTFILES_DIR/.zsh/env.local.zsh"; do
    snapshot_path "$path"
  done
  SNAPSHOT_READY=true
}
snapshot_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local backup="$ROLLBACK_DIR/originals/$(printf '%03d' "${#SNAPSHOT_PATHS[@]}")"
    run_command mv "$path" "$backup"
    SNAPSHOT_PATHS+=("$path")
    SNAPSHOT_BACKUPS+=("$backup")
    log_info "[退避] $path"
  fi
}
install_packages() {
  local package
  MISSING_FORMULAE=()
  MISSING_CASKS=()
  if [[ "$DRY_RUN" == "true" ]]; then
    MISSING_FORMULAE=("${FORMULAE[@]}")
    MISSING_CASKS=("${CASKS[@]}")
  else
    for package in "${FORMULAE[@]}"; do
      if brew list --formula "$package" >/dev/null 2>&1; then
        log_info "[スキップ] formula は導入済みです: $package"
        SKIPPED_ITEMS+=("formula: $package")
      else
        log_info "[不足] formula: $package"
        MISSING_FORMULAE+=("$package")
      fi
    done
    for package in "${CASKS[@]}"; do
      if brew list --cask "$package" >/dev/null 2>&1; then
        log_info "[スキップ] cask は導入済みです: $package"
        SKIPPED_ITEMS+=("cask: $package")
      else
        log_info "[不足] cask: $package"
        MISSING_CASKS+=("$package")
      fi
    done
  fi
  if ((${#MISSING_FORMULAE[@]})); then
    MISSING_ITEMS+=("formula: ${MISSING_FORMULAE[*]}")
    run_command brew install "${MISSING_FORMULAE[@]}"
  fi
  if ((${#MISSING_CASKS[@]})); then
    MISSING_ITEMS+=("cask: ${MISSING_CASKS[*]}")
    run_command brew install --cask "${MISSING_CASKS[@]}"
  fi
  if ! $DRY_RUN && brew list --formula borders >/dev/null 2>&1; then
    BORDERS_PREEXISTING=true
  fi
}
install_php_debug_adapter() {
  local debug_dir="$HOME/vscode-php-debug"
  if [[ "$DRY_RUN" == "true" ]]; then
    MISSING_ITEMS+=("PHP デバッグ拡張")
    run_command git clone "https://github.com/xdebug/vscode-php-debug.git" "$debug_dir"
    run_command npm --prefix "$debug_dir" install
    run_command npm --prefix "$debug_dir" run build
    return
  fi
  if [[ -e "$debug_dir" || -L "$debug_dir" ]]; then
    [[ -d "$debug_dir/.git" ]] || fail "既存の PHP デバッグ拡張ディレクトリが Git リポジトリではありません: $debug_dir"
    [[ -f "$debug_dir/out/phpDebug.js" ]] || fail "既存の PHP デバッグ拡張が未ビルドです。変更せず中断します: $debug_dir"
    SKIPPED_ITEMS+=("PHP デバッグ拡張は導入済みです。")
    log_info "[スキップ] PHP デバッグ拡張は導入済みです。"
    return
  fi
  PHP_DEBUG_CREATED=true
  run_command git clone "https://github.com/xdebug/vscode-php-debug.git" "$debug_dir"
  run_command npm --prefix "$debug_dir" install
  run_command npm --prefix "$debug_dir" run build
}
install_dotfiles_configuration() {
  local install_script="$DOTFILES_DIR/.bin/install.sh"
  [[ "$DRY_RUN" == "true" || -x "$install_script" ]] || fail "dotfiles のインストールスクリプトが見つかりません: $install_script"
  [[ -e "$DOTFILES_DIR/.mcp.json" ]] || record_warning ".mcp.json は存在しないためスキップします。"
  [[ -e "$DOTFILES_DIR/.agents" ]] || record_warning ".agents は管理対象がないためスキップします。"
  export DOTFILES_INSTALL_ROOT="$DOTFILES_DIR"
  run_command bash "$install_script"
}
install_janky_borders() {
  local install_script="$DOTFILES_DIR/.bin/install-janky-borders.sh"
  [[ "$DRY_RUN" == "true" || -x "$install_script" ]] || fail "JankyBorders のインストールスクリプトが見つかりません: $install_script"
  run_command bash "$install_script"
}
install_neovim_plugins() {
  run_command nvim --headless '+Lazy! sync' '+qa'
}
run_command() {
  log_info "[実行] $(printf '%q ' "$@")"
  if [[ "$DRY_RUN" == "true" ]]; then return 0; fi
  "$@"
}
handle_failure() {
  # macOS 標準の Bash 3 では、set -u 中の空配列追加を安全に扱えないため一時的に解除する。
  set +u
  local status="$1" line="$2"
  [[ "$ROLLBACK_ACTIVE" == "true" ]] && exit "$status"
  ROLLBACK_ACTIVE=true
  FAILURE_ITEMS+=("${CURRENT_STEP:-初期化}")
  printf '[失敗] %s\n' "${CURRENT_STEP:-初期化}" >&2
  rollback
  print_summary "失敗"
  exit "$status"
}
rollback() {
  set +e
  printf '[復元] 変更した設定と今回作成したデータを復元します。\n' >&2
  local path index
  if [[ -n "$ROLLBACK_DIR" ]]; then
    if [[ "$SNAPSHOT_READY" == "true" ]]; then
      for path in "${MANAGED_HOME_PATHS[@]}" "$DOTFILES_DIR/.bash/env.local.bash" "$DOTFILES_DIR/.zsh/env.local.zsh"; do
        rm -rf "$path"
      done
    else
      for path in "${SNAPSHOT_PATHS[@]}"; do
        rm -rf "$path"
      done
      log_info "[復元] 退避途中のため、退避済みの設定だけを復元します。"
    fi
    for ((index=${#SNAPSHOT_PATHS[@]}-1; index>=0; index--)); do
      path="${SNAPSHOT_PATHS[$index]}"
      mkdir -p "$(dirname "$path")"
      mv "${SNAPSHOT_BACKUPS[$index]}" "$path"
    done
    if [[ "$CODEX_DIRECTORY_EXISTED" != "true" ]]; then rmdir "$HOME/.codex" 2>/dev/null; fi
  else
    log_info "[復元] 既存設定の退避前だったため、既存設定には触れません。"
  fi
  if [[ "$PHP_DEBUG_CREATED" == "true" ]]; then rm -rf "$HOME/vscode-php-debug"; fi
  if [[ "$DOTFILES_CREATED" == "true" ]]; then rm -rf "$DOTFILES_DIR"; fi
  rollback_homebrew
  printf '[復元] 完了しました。退避先: %s\n' "${ROLLBACK_DIR:-なし}" >&2
  set -e
}
rollback_homebrew() {
  [[ "$DRY_RUN" == "true" || ! -x "$(command -v brew 2>/dev/null)" ]] && return
  local package
  for package in "${MISSING_FORMULAE[@]}"; do
    if brew list --formula "$package" >/dev/null 2>&1; then
      brew uninstall --formula "$package" >/dev/null 2>&1 || record_warning "formula の復元に失敗しました: $package"
    fi
  done
  for package in "${MISSING_CASKS[@]}"; do
    if brew list --cask "$package" >/dev/null 2>&1; then
      brew uninstall --cask "$package" >/dev/null 2>&1 || record_warning "cask の復元に失敗しました: $package"
    fi
  done
  if [[ "$BORDERS_PREEXISTING" != "true" ]] && brew list --formula borders >/dev/null 2>&1; then
    brew services stop borders >/dev/null 2>&1
    brew uninstall --formula borders >/dev/null 2>&1
  fi
  if [[ "$HOMEBREW_CREATED" == "true" ]] && command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" >/dev/null 2>&1 || record_warning "Homebrew 自体の復元に失敗しました。"
  fi
}
record_warning() {
  WARNING_ITEMS+=("$1")
  log_info "[警告] $1"
}
print_completion_message() {
  log_info "macOS の初期構成処理が完了しました。"
  log_info "設定変更後は dotfiles 側を更新すると、リンク先へ反映されます。"
}
print_summary() {
  # macOS 標準の Bash 3 では、set -u 中の空配列参照を安全に扱えないため一時的に解除する。
  set +u
  local result="$1" item
  printf '[結果] %s\n' "$result"
  printf '  完了: %d\n' "${#COMPLETED_STEPS[@]}"
  for item in "${COMPLETED_STEPS[@]}"; do printf '    - %s\n' "$item"; done
  printf '  スキップ: %d\n' "${#SKIPPED_ITEMS[@]}"
  for item in "${SKIPPED_ITEMS[@]}"; do printf '    - %s\n' "$item"; done
  printf '  不足・導入対象: %d\n' "${#MISSING_ITEMS[@]}"
  for item in "${MISSING_ITEMS[@]}"; do printf '    - %s\n' "$item"; done
  printf '  警告: %d\n' "${#WARNING_ITEMS[@]}"
  for item in "${WARNING_ITEMS[@]}"; do printf '    - %s\n' "$item"; done
  printf '  失敗: %d\n' "${#FAILURE_ITEMS[@]}"
  for item in "${FAILURE_ITEMS[@]}"; do printf '    - %s\n' "$item"; done
  [[ -n "$ROLLBACK_DIR" ]] && printf '  退避先: %s\n' "$ROLLBACK_DIR"
  set -u
}
print_usage() {
  cat <<'USAGE'
Usage: bash .bin/bootstrap-macos.sh [--dry-run] [--directory PATH] [--repository URL] [--env=localdev]
新しい macOS にシェル、Neovim、Starship、WezTerm、JankyBorders、Codex の管理対象設定と関連ツールを導入します。
失敗時は設定と今回作成したデータを復元します。既存の Git リポジトリと導入済みパッケージは変更しません。
USAGE
}
log_info() {
  printf '[INFO] %s\n' "$1"
}
fail() {
  printf '[ERROR] %s\n' "$1" >&2
  return 1
}
main "$@"
