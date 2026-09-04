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
  "bash $ROOT_DIR/dry-run-dotfiles/.bin/install.sh" \
  "[開始] macOS 環境の確認" \
  "[実行] brew install" \
  "完了:" \
  "不足・導入対象:" \
  "警告:" \
  "失敗:" \
  "[結果] 成功"; do
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

# 既存設定の退避より前に失敗しても、既存設定を削除しないことを確認する。
EARLY_ROOT="$TEMP_ROOT/early"
EARLY_BIN="$EARLY_ROOT/bin"
EARLY_HOME="$EARLY_ROOT/home"
mkdir -p "$EARLY_BIN" "$EARLY_HOME"
printf '%s\n' '#!/usr/bin/env bash' 'printf "%s\n" Darwin' > "$EARLY_BIN/uname"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$EARLY_BIN/git"
chmod +x "$EARLY_BIN/uname" "$EARLY_BIN/git"
printf '%s\n' 'original early configuration' > "$EARLY_HOME/.zshrc"
if HOME="$EARLY_HOME" PATH="$EARLY_BIN" bash "$BOOTSTRAP_SCRIPT" --env=localdev --directory "$EARLY_ROOT/dotfiles" >/tmp/bootstrap-early-failure-output 2>&1; then
  echo "退避前に失敗する構成を成功として扱いました。" >&2
  exit 1
fi
if [[ "$(<"$EARLY_HOME/.zshrc")" != "original early configuration" ]]; then
  echo "退避前の失敗で既存の .zshrc が削除されました。" >&2
  exit 1
fi

# Homebrew の失敗を模擬し、既存設定と clone 途中のディレクトリが復元されることを確認する。
FAIL_ROOT="$(mktemp -d)"
FAIL_BIN="$FAIL_ROOT/bin"
FAIL_HOME="$FAIL_ROOT/home"
FAIL_TARGET="$FAIL_ROOT/dotfiles"
mkdir -p "$FAIL_BIN" "$FAIL_HOME"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'target="${3:-}"' 'mkdir -p "$target/.git"' > "$FAIL_BIN/git"
printf '%s\n' '#!/usr/bin/env bash' 'exit 1' > "$FAIL_BIN/brew"
chmod +x "$FAIL_BIN/git" "$FAIL_BIN/brew"
printf '%s\n' 'original zsh configuration' > "$FAIL_HOME/.zshrc"
if HOME="$FAIL_HOME" PATH="$FAIL_BIN:/usr/bin:/bin" bash "$BOOTSTRAP_SCRIPT" --env=localdev --directory "$FAIL_TARGET" --repository test://dotfiles >/tmp/bootstrap-rollback-output 2>&1; then
  echo "失敗する Homebrew を成功として扱いました。" >&2
  exit 1
fi

if ! grep -Fq "[失敗]" /tmp/bootstrap-rollback-output || ! grep -Fq "[復元]" /tmp/bootstrap-rollback-output; then
  echo "失敗時の復元結果が表示されていません。" >&2
  exit 1
fi

if [[ "$(<"$FAIL_HOME/.zshrc")" != "original zsh configuration" ]]; then
  echo "失敗後に既存の .zshrc が復元されていません。" >&2
  exit 1
fi

if [[ -e "$FAIL_TARGET" || -L "$FAIL_TARGET" ]]; then
  echo "失敗後に clone 途中の dotfiles が残っています。" >&2
  exit 1
fi

rm -rf "$FAIL_ROOT"

echo "PASS: macOS 初期構成は WezTerm とフォントを導入し、既存ディレクトリを保護します。"
