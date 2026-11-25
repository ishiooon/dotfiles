#!/usr/bin/env bash
set -euo pipefail

# ローカル開発環境向けの実行指定が無い場合は失敗させ、誤実行を防止する。
if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定して実行してください。" >&2
  exit 2
fi

# このテストファイルから見たプロジェクトルートを求める。
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/.bin/install-janky-borders.sh"

# インストール補助スクリプトが無い場合は、JankyBorders の導入手順を再現できない。
if [[ ! -f "$INSTALL_SCRIPT" ]]; then
  echo "JankyBorders のインストール補助スクリプトが見つかりません: $INSTALL_SCRIPT" >&2
  exit 1
fi

# 実行権限を確認し、手元のターミナルから直接呼び出せる状態を保つ。
if [[ ! -x "$INSTALL_SCRIPT" ]]; then
  echo "JankyBorders のインストール補助スクリプトに実行権限がありません: $INSTALL_SCRIPT" >&2
  exit 1
fi

# ドライランでは Homebrew を実行せず、実環境を汚さずに導入手順だけを確認する。
OUTPUT="$(bash "$INSTALL_SCRIPT" --env=localdev --dry-run)"

for expected in \
  "brew tap FelixKratz/formulae" \
  "brew install felixkratz/formulae/borders" \
  "brew services start borders" \
  "borders"; do
  if ! grep -Fq "$expected" <<<"$OUTPUT"; then
    echo "ドライランに期待した手順が含まれていません: $expected" >&2
    echo "実際の出力:" >&2
    echo "$OUTPUT" >&2
    exit 1
  fi
done

# 新しい Homebrew の信頼ルールを模擬し、短い名前では導入できない状況を検証する。
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
TEST_HOME="$TEMP_ROOT/home"
TEST_BIN="$TEMP_ROOT/bin"
mkdir -p "$TEST_HOME" "$TEST_BIN"
cat > "$TEST_BIN/brew" <<'BREW'
#!/bin/bash
set -euo pipefail
printf '%s\n' "$*" >> "$BORDERS_TEST_LOG"
case "$*" in
  'tap FelixKratz/formulae') exit 0 ;;
  'install borders')
    echo 'Error: Refusing to load formula felixkratz/formulae/borders from untrusted tap felixkratz/formulae.' >&2
    exit 1 ;;
  'install felixkratz/formulae/borders') touch "$BORDERS_TEST_TRUST" ;;
  'services start borders') [[ -f "$BORDERS_TEST_TRUST" ]] ;;
  *) echo "想定外の Homebrew 操作: $*" >&2; exit 1 ;;
esac
BREW
chmod +x "$TEST_BIN/brew"
HOME="$TEST_HOME" PATH="$TEST_BIN:/usr/bin:/bin:/usr/sbin:/sbin" \
  BORDERS_TEST_LOG="$TEMP_ROOT/brew.log" BORDERS_TEST_TRUST="$TEMP_ROOT/trusted" \
  /bin/bash "$INSTALL_SCRIPT" >"$TEMP_ROOT/output" 2>&1 || {
    cat "$TEMP_ROOT/output" >&2
    exit 1
  }
[[ -f "$TEMP_ROOT/trusted" ]]
[[ -L "$TEST_HOME/.config/borders/bordersrc" ]]
grep -Fxq 'services start borders' "$TEMP_ROOT/brew.log"

echo "PASS: 配布元を指定して JankyBorders だけを信頼・導入し、サービスを起動できます。"
