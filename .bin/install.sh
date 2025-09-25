#!/bin/bash
# 完全なdotfiles自動セットアップスクリプト
# nvim中心の開発環境を$HOME/dotfilesから自動展開
# ===================================================

# エラーハンドリング設定
set -e
trap 'echo "Error occurred at line $LINENO. Installation failed."; exit 1' ERR

# カラー出力設定
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# バックアップディレクトリ作成
backup_dir="$HOME/dotbackup/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"
log_info "Backup directory created: $backup_dir"

# シンボリックリンク作成関数
create_symlink() {
    local src="$1"
    local dest="$2"
    local type="$3"  # file or dir
    
    # ソースが存在するかチェック
    if [ ! -e "$src" ]; then
        log_warn "Source does not exist: $src - skipping"
        return
    fi
    
    # 既存ファイル・ディレクトリの処理
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ -L "$dest" ]; then
            # 既にシンボリックリンクの場合
            local current_target=$(readlink "$dest")
            if [ "$current_target" = "$src" ]; then
                log_info "$(basename $dest) is already correctly linked"
                return
            else
                log_warn "Removing existing symbolic link: $dest -> $current_target"
                rm "$dest"
            fi
        else
            # 通常のファイル・ディレクトリの場合
            log_warn "Backing up existing $type: $(basename $dest)"
            mv "$dest" "$backup_dir/$(basename $dest)"
        fi
    fi
    
    # シンボリックリンク作成
    ln -s "$src" "$dest"
    log_info "Created symbolic link: $(basename $dest) -> $src"
}

log_info "Starting dotfiles installation..."

# ===================================================
# 1. Shell設定ファイル
# ===================================================
log_info "Setting up shell configuration files..."

create_symlink "$HOME/dotfiles/.bashrc" "$HOME/.bashrc" "file"
create_symlink "$HOME/dotfiles/.zshrc" "$HOME/.zshrc" "file"

# ===================================================
# 2. Shell設定ディレクトリ
# ===================================================
log_info "Setting up shell configuration directories..."

create_symlink "$HOME/dotfiles/.bash" "$HOME/.bash" "dir"
create_symlink "$HOME/dotfiles/.zsh" "$HOME/.zsh" "dir"

# ===================================================
# 3. 設定ディレクトリ全体 (.config)
# ===================================================
log_info "Setting up .config directory..."

create_symlink "$HOME/dotfiles/.config" "$HOME/.config" "dir"

# ===================================================
# 4. 便利スクリプト・ツール
# ===================================================
log_info "Setting up utility scripts and tools..."

create_symlink "$HOME/dotfiles/.bin" "$HOME/.bin" "dir"
create_symlink "$HOME/dotfiles/.claude" "$HOME/.claude" "dir"

# ===================================================
# 5. 設定ファイル
# ===================================================
log_info "Setting up configuration files..."

create_symlink "$HOME/dotfiles/.mcp.json" "$HOME/.mcp.json" "file"

# ===================================================
# 6. 環境変数設定ファイルの作成
# ===================================================
log_info "Setting up environment configuration files..."

# bash環境変数ファイル
if [ ! -f "$HOME/.bash/env.local.bash" ]; then
    if [ -f "$HOME/dotfiles/.bash/env.local.bash.example" ]; then
        cp "$HOME/dotfiles/.bash/env.local.bash.example" "$HOME/.bash/env.local.bash"
        log_info "Created .bash/env.local.bash from example file"
        log_warn "Please edit $HOME/.bash/env.local.bash to add your API keys"
    fi
fi

# zsh環境変数ファイル  
if [ ! -f "$HOME/.zsh/env.local.zsh" ]; then
    if [ -f "$HOME/dotfiles/.zsh/env.local.zsh.example" ]; then
        cp "$HOME/dotfiles/.zsh/env.local.zsh.example" "$HOME/.zsh/env.local.zsh"
        log_info "Created .zsh/env.local.zsh from example file"
        log_warn "Please edit $HOME/.zsh/env.local.zsh to add your API keys"
    fi
fi

# ===================================================
# 7. PATHへの.binディレクトリ追加確認
# ===================================================
log_info "Checking PATH configuration..."

# 現在のシェルに応じてPATHが設定されているかチェック
if [[ ":$PATH:" != *":$HOME/.bin:"* ]]; then
    log_warn "~/.bin is not in PATH. Please restart your shell or run 'source ~/.bashrc' or 'source ~/.zshrc'"
fi

# ===================================================
# 8. インストール完了
# ===================================================
log_info "Installation completed successfully!"
echo ""
log_info "Next steps:"
echo "  1. Edit environment files if needed:"
echo "     - ~/.bash/env.local.bash (for bash users)"
echo "     - ~/.zsh/env.local.zsh (for zsh users)"
echo "  2. Restart your shell or run:"
echo "     - 'source ~/.bashrc' (for bash)"
echo "     - 'source ~/.zshrc' (for zsh)"
echo "  3. Open nvim and run ':Lazy sync' to install plugins"
echo ""
log_info "Backup files are stored in: $backup_dir"

