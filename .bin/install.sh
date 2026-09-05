#!/usr/bin/env bash
set -Eeuo pipefail

# dotfiles が管理する設定をホームへ安全にリンクする単独実行用インストーラー。
DOTFILES_DIR="${DOTFILES_INSTALL_ROOT:-$HOME/dotfiles}"
DRY_RUN=false
BACKUP_DIR=""
TRANSACTION_STARTED=false
ROLLBACK_ACTIVE=false
declare -a BACKUP_TARGETS=()
declare -a BACKUP_PATHS=()
declare -a CREATED_PATHS=()

main() {
    trap 'handle_failure "$?" "$LINENO"' ERR
    parse_arguments "$@"
    validate_dotfiles
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[予定] ドライランを開始します。既存設定は変更しません。"
    else
        prepare_backup
    fi
    install_shell_files
    install_shell_directories
    install_config_directory
    install_tool_directories
    install_codex_configuration
    install_mcp_configuration
    install_environment_files
    report_path_status
    print_summary "成功"
    trap - ERR
}

parse_arguments() {
    while (($#)); do
        case "$1" in
            --dry-run) DRY_RUN=true ;;
            --env=localdev) ;;
            -h|--help) print_usage; exit 0 ;;
            *) fail "未対応の引数です: $1" ;;
        esac
        shift
    done
}

validate_dotfiles() {
    local home_dir dotfiles_dir
    [[ -n "$DOTFILES_DIR" ]] || fail "dotfiles の配置先が空です。"
    [[ -d "$DOTFILES_DIR" ]] || fail "dotfiles の配置先が見つかりません: $DOTFILES_DIR"
    home_dir="$(cd "$HOME" && pwd -P)"
    dotfiles_dir="$(cd "$DOTFILES_DIR" && pwd -P)"
    [[ "$dotfiles_dir" != "$home_dir" ]] || fail "dotfiles の配置先に HOME 自体は指定できません。"
}

prepare_backup() {
    local backup_root="$HOME/dotbackup"
    mkdir -p "$backup_root"
    BACKUP_DIR="$(mktemp -d "$backup_root/install-XXXXXX")"
    TRANSACTION_STARTED=true
    log_info "[退避] 退避先を作成しました: $BACKUP_DIR"
}

install_shell_files() {
    log_info "[開始] シェル設定ファイル"
    create_symlink "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc"
    create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    log_info "[完了] シェル設定ファイル"
}

install_shell_directories() {
    log_info "[開始] シェル設定ディレクトリ"
    create_symlink "$DOTFILES_DIR/.bash" "$HOME/.bash"
    create_symlink "$DOTFILES_DIR/.zsh" "$HOME/.zsh"
    log_info "[完了] シェル設定ディレクトリ"
}

install_config_directory() {
    log_info "[開始] アプリケーション設定"
    create_symlink "$DOTFILES_DIR/.config" "$HOME/.config"
    log_info "[完了] アプリケーション設定"
}

install_tool_directories() {
    log_info "[開始] 補助ツール設定"
    create_symlink "$DOTFILES_DIR/.bin" "$HOME/.bin"
    create_symlink "$DOTFILES_DIR/.claude" "$HOME/.claude"
    create_symlink "$DOTFILES_DIR/.agents" "$HOME/.agents"
    log_info "[完了] 補助ツール設定"
}

install_codex_configuration() {
    log_info "[開始] Codex 管理対象設定"
    ensure_codex_directory
    create_symlink "$DOTFILES_DIR/.codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    create_symlink "$DOTFILES_DIR/.codex/agents" "$HOME/.codex/agents"
    log_info "[完了] Codex 管理対象設定"
}

install_mcp_configuration() {
    log_info "[開始] MCP 設定"
    create_symlink "$DOTFILES_DIR/.mcp.json" "$HOME/.mcp.json"
    log_info "[完了] MCP 設定"
}

install_environment_files() {
    log_info "[開始] ローカル環境変数の雛形"
    install_environment_file "$DOTFILES_DIR/.bash/env.local.bash.example" "$HOME/.bash/env.local.bash"
    install_environment_file "$DOTFILES_DIR/.zsh/env.local.zsh.example" "$HOME/.zsh/env.local.zsh"
    log_info "[完了] ローカル環境変数の雛形"
}

ensure_codex_directory() {
    if [[ -e "$HOME/.codex" || -L "$HOME/.codex" ]]; then
        mkdir -p "$HOME/.codex"
        return
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[予定] ディレクトリを作成します: $HOME/.codex"
        return
    fi
    mkdir -p "$HOME/.codex"
    CREATED_PATHS+=("$HOME/.codex")
    log_info "[作成] $HOME/.codex"
}

create_symlink() {
    local source="$1" target="$2" current_target
    if [[ ! -e "$source" && ! -L "$source" ]]; then
        log_info "[警告] 管理対象が存在しないためスキップします: $source"
        return
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            current_target="$(readlink "$target")"
            if [[ "$current_target" == "$source" ]]; then
                log_info "[スキップ] 既に正しいリンクです: $target"
                return
            fi
        elif [[ "$DRY_RUN" == "true" ]]; then
            log_info "[予定] 既存の $target を退避します。"
        fi
        if [[ "$DRY_RUN" != "true" ]]; then
            backup_existing_path "$target"
        fi
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[予定] ln -s $source $target"
        return
    fi
    ln -s "$source" "$target"
    CREATED_PATHS+=("$target")
    log_info "[作成] $target -> $source"
}

install_environment_file() {
    local source="$1" target="$2"
    if [[ ! -f "$source" ]]; then
        log_info "[警告] 雛形が存在しないためスキップします: $source"
        return
    fi
    if [[ -f "$target" && ! -L "$target" ]]; then
        log_info "[スキップ] ローカル環境変数は既に存在します: $target"
        return
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$DRY_RUN" != "true" ]]; then
            backup_existing_path "$target"
        fi
    fi
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[予定] cp $source $target"
        return
    fi
    mkdir -p "$(dirname "$target")"
    cp "$source" "$target"
    CREATED_PATHS+=("$target")
    log_info "[作成] $target（雛形から作成）"
    log_info "[警告] APIキーなどの値を必要に応じて設定してください: $target"
}

report_path_status() {
    if [[ ":${PATH:-}:" == *":$HOME/.bin:"* ]]; then
        log_info "[確認] $HOME/.bin は PATH に含まれています。"
    else
        log_info "[警告] $HOME/.bin が PATH にありません。シェルを再起動してください。"
    fi
}

handle_failure() {
    set +u
    local status="$1"
    [[ "$ROLLBACK_ACTIVE" == "true" ]] && exit "$status"
    ROLLBACK_ACTIVE=true
    log_error "[失敗] install.sh の処理を中断しました。"
    rollback
    print_summary "失敗"
    exit "$status"
}

rollback() {
    set +e
    log_info "[復元] 作成途中のリンクと退避済み設定を復元します。"
    local index path
    if [[ "$TRANSACTION_STARTED" != "true" ]]; then
        log_info "[復元] 退避開始前だったため、既存設定には触れません。"
        return
    fi
    for ((index=${#CREATED_PATHS[@]}-1; index>=0; index--)); do
        path="${CREATED_PATHS[$index]}"
        rm -rf "$path"
    done
    for ((index=${#BACKUP_TARGETS[@]}-1; index>=0; index--)); do
        path="${BACKUP_TARGETS[$index]}"
        mkdir -p "$(dirname "$path")"
        mv "${BACKUP_PATHS[$index]}" "$path"
    done
    log_info "[復元] 完了しました。退避先は保持しています: $BACKUP_DIR"
    set -e
}

backup_existing_path() {
    local target="$1"
    local index="${#BACKUP_TARGETS[@]}"
    local backup="$BACKUP_DIR/$(printf '%03d' "$index")-${target##*/}"
    mv "$target" "$backup"
    BACKUP_TARGETS+=("$target")
    BACKUP_PATHS+=("$backup")
    log_info "[退避] $target -> $backup"
}

print_summary() {
    set +u
    local result="$1"
    printf '[結果] %s\n' "$result"
    printf '  作成したリンク・ファイル: %d\n' "${#CREATED_PATHS[@]}"
    printf '  退避した設定: %d\n' "${#BACKUP_TARGETS[@]}"
    printf '  退避先: %s\n' "${BACKUP_DIR:-なし}"
    set -u
}

print_usage() {
    cat <<'USAGE'
Usage: bash .bin/install.sh [--dry-run] [--env=localdev]

dotfiles の設定をホームディレクトリへ安全にリンクします。
既存設定は ~/dotbackup/ 配下へ退避し、失敗時は作成途中の変更を復元します。
USAGE
}

log_info() {
    printf '[INFO] %s\n' "$1"
}

log_error() {
    printf '[ERROR] %s\n' "$1" >&2
}

fail() {
    log_error "$1"
    return 1
}

main "$@"
