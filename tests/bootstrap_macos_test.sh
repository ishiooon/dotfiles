#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_SCRIPT="$ROOT_DIR/.bin/bootstrap-macos.sh"

# 新しい Mac 向けの入口が無い場合は、初期構成手順を再現できない。
if [[ ! -f "$BOOTSTRAP_SCRIPT" ]]; then
  echo "macOS 初期構成スクリプトが見つかりません: $BOOTSTRAP_SCRIPT" >&2
  exit 1
fi

if [[ ! -x "$BOOTSTRAP_SCRIPT" ]]; then
  echo "macOS 初期構成スクリプトに実行権限がありません: $BOOTSTRAP_SCRIPT" >&2
  exit 1
fi

# 実ホームと Homebrew を変更しないよう、ドライランだけを検証する。
OUTPUT="$(HOME="$ROOT_DIR/dry-run-home" bash "$BOOTSTRAP_SCRIPT" --env=localdev --dry-run --directory "$ROOT_DIR/dry-run-dotfiles")"

for expected in \
  "git clone https://github.com/ishiooon/dotfiles.git" \
  "brew install neovim starship fzf ripgrep fd lazygit deno gh node php w3m coreutils" \
  "brew install --cask wezterm font-udev-gothic-nf" \
  "bash $ROOT_DIR/dry-run-dotfiles/.bin/install-janky-borders.sh" \
  "nvim --headless" \
  "git clone https://github.com/xdebug/vscode-php-debug.git $ROOT_DIR/dry-run-home/vscode-php-debug" \
  "npm --prefix $ROOT_DIR/dry-run-home/vscode-php-debug install" \
  "npm --prefix $ROOT_DIR/dry-run-home/vscode-php-debug run build" \
  "bash $ROOT_DIR/dry-run-dotfiles/.bin/install.sh"; do
  if ! grep -Fq "$expected" <<<"$OUTPUT"; then
    echo "ドライランに期待した初期構成手順が含まれていません: $expected" >&2
    echo "実際の出力:" >&2
    echo "$OUTPUT" >&2
    exit 1
  fi
done

if [[ -e "$ROOT_DIR/dry-run-dotfiles" || -L "$ROOT_DIR/dry-run-dotfiles" ]]; then
  echo "ドライランでリポジトリのディレクトリが作成されています。" >&2
  exit 1
fi

# リポジトリ以外の既存ディレクトリを上書きしないことを確認する。
TEMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

EXISTING_DIR="$TEMP_ROOT/dotfiles"
mkdir -p "$EXISTING_DIR"
if bash "$BOOTSTRAP_SCRIPT" --env=localdev --dry-run --directory "$EXISTING_DIR" >/dev/null 2>&1; then
  echo "既存の非 Git ディレクトリを許可してしまいました。" >&2
  exit 1
fi

echo "PASS: macOS 初期構成は WezTerm とフォントを導入し、既存ディレクトリを保護します。"
