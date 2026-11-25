# Bash と zsh の両方から読み込み、ターミナルで使う共通の環境変数を設定する。
# 個別の env.local ファイルは呼び出し元で後から読み込み、利用者の指定を優先する。
dotfiles_initialize_shell_environment() {
    local homebrew_prefix command_dir
    if [[ "$OSTYPE" == darwin* ]]; then
        for homebrew_prefix in /opt/homebrew /usr/local; do
            [[ -x "$homebrew_prefix/bin/brew" ]] || continue
            # 初期化済みの場合は、ローカル設定で選んだ検索順位を変えない。
            if [[ "${HOMEBREW_PREFIX:-}" != "$homebrew_prefix" ||
                ":${PATH:-}:" != *":$homebrew_prefix/bin:"* ||
                ":${PATH:-}:" != *":$homebrew_prefix/sbin:"* ]]; then
                eval "$("$homebrew_prefix/bin/brew" shellenv)"
            fi
            break
        done
    fi

    # 利用者が配置したコマンドを検索対象に加え、設定の再読込による重複を除く。
    export DENO_INSTALL="$HOME/.deno"
    for command_dir in "$DENO_INSTALL/bin" "$HOME/.local/bin" "$HOME/.bin"; do
        case ":${PATH:-}:" in
            *":$command_dir:"*) ;;
            *) PATH="$command_dir${PATH:+:$PATH}" ;;
        esac
    done
    export PATH="$(dotfiles_unique_path "${PATH:-}")"
}

# 最初に現れたディレクトリの検索順位を保つ。空の要素による現在のディレクトリ指定も保持する。
dotfiles_unique_path() {
    local remaining="$1" entry result="" separator="" seen=":"
    while :; do
        entry="${remaining%%:*}"
        case "$seen" in
            *":$entry:"*) ;;
            *)
                result="$result$separator$entry"
                separator=":"
                seen="$seen$entry:"
                ;;
        esac
        [[ "$remaining" == *:* ]] || break
        remaining="${remaining#*:}"
    done
    printf '%s' "$result"
}

dotfiles_initialize_shell_environment
