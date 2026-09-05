#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/.bin/install.sh"

# 実ホームを汚さないため、ソースと HOME の両方を一時ディレクトリへ隔離する。
TEMP_ROOT="$(mktemp -d)"
cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

DOTFILES_FIXTURE="$TEMP_ROOT/dotfiles"
FAIL_HOME="$TEMP_ROOT/fail-home"
mkdir -p "$DOTFILES_FIXTURE"/{.agents,.bash,.claude,.config,.codex/agents,.zsh,.bin}
printf '%s\n' '#!/usr/bin/env bash' > "$DOTFILES_FIXTURE/.bashrc"
printf '%s\n' '#!/usr/bin/env zsh' > "$DOTFILES_FIXTURE/.zshrc"
printf '%s\n' 'export TEST_VALUE=example' > "$DOTFILES_FIXTURE/.bash/env.local.bash.example"
printf '%s\n' 'export TEST_VALUE=example' > "$DOTFILES_FIXTURE/.zsh/env.local.zsh.example"
printf '%s\n' '{"mcpServers":{}}' > "$DOTFILES_FIXTURE/.mcp.json"
mkdir -p "$DOTFILES_FIXTURE/.config/sample"
printf '%s\n' 'configuration' > "$DOTFILES_FIXTURE/.config/sample/settings"
mkdir -p "$FAIL_HOME/.config"
printf '%s\n' 'original zsh configuration' > "$FAIL_HOME/.zshrc"
printf '%s\n' 'original config' > "$FAIL_HOME/.config/original"
printf '%s\n' 'original codex state' > "$FAIL_HOME/.codex"

# 途中で失敗した場合に、退避済み設定と作成済みリンクが元へ戻ることを確認する。
if HOME="$FAIL_HOME" DOTFILES_INSTALL_ROOT="$DOTFILES_FIXTURE" bash "$INSTALL_SCRIPT" --env=localdev >/tmp/install-rollback-output 2>&1; then
  echo "失敗する install.sh を成功として扱いました。" >&2
  exit 1
fi

if [[ "$(<"$FAIL_HOME/.zshrc")" != "original zsh configuration" ]]; then
  echo "失敗後に .zshrc が復元されていません。" >&2
  exit 1
fi
if [[ "$(<"$FAIL_HOME/.config/original")" != "original config" ]]; then
  echo "失敗後に .config が復元されていません。" >&2
  exit 1
fi
if [[ "$(<"$FAIL_HOME/.codex")" != "original codex state" ]]; then
  echo "失敗後に .codex が復元されていません。" >&2
  exit 1
fi
for path in .bashrc .zshrc .bash .zsh .config .bin .claude .agents .mcp.json; do
  if [[ -L "$FAIL_HOME/$path" ]]; then
    echo "失敗後に作成途中のリンクが残っています: $path" >&2
    exit 1
  fi
done
if ! grep -Fq "[復元]" /tmp/install-rollback-output; then
  echo "失敗時の復元結果が表示されていません。" >&2
  exit 1
fi

# ドライランでは、既存設定と一時退避先を変更しないことを確認する。
DRY_HOME="$TEMP_ROOT/dry-home"
mkdir -p "$DRY_HOME"
printf '%s\n' 'original' > "$DRY_HOME/.zshrc"
DRY_OUTPUT="$(HOME="$DRY_HOME" DOTFILES_INSTALL_ROOT="$DOTFILES_FIXTURE" bash "$INSTALL_SCRIPT" --env=localdev --dry-run)"
if [[ "$(<"$DRY_HOME/.zshrc")" != "original" || -L "$DRY_HOME/.zshrc" ]]; then
  echo "ドライランで既存設定が変更されました。" >&2
  exit 1
fi
if ! grep -Fq "[予定]" <<<"$DRY_OUTPUT" || ! grep -Fq "完了" <<<"$DRY_OUTPUT"; then
  echo "ドライランの予定表示が不足しています。" >&2
  exit 1
fi

# dotfiles の配置先が存在しない場合は、リンク処理を開始せず失敗することを確認する。
if HOME="$TEMP_ROOT/missing-home" DOTFILES_INSTALL_ROOT="$TEMP_ROOT/missing-dotfiles" bash "$INSTALL_SCRIPT" --env=localdev >/dev/null 2>&1; then
  echo "存在しない dotfiles 配置先を成功として扱いました。" >&2
  exit 1
fi

# HOME 自体を dotfiles の配置先として指定した場合も、実体パスで拒否することを確認する。
if HOME="$DRY_HOME" DOTFILES_INSTALL_ROOT="$DRY_HOME/" bash "$INSTALL_SCRIPT" --env=localdev >/dev/null 2>&1; then
  echo "HOME 自体を dotfiles 配置先として許可しました。" >&2
  exit 1
fi

echo "PASS: install.sh は失敗時に復元し、ドライランと配置先検証を安全に実行できます。"
