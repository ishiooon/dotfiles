# 環境変数の設定（テンプレート）
# 実際のAPIキーは .zsh/env.local.zsh で設定してください

# ローカル環境変数ファイルが存在する場合は読み込む
if [[ -f ~/.zsh/env.local.zsh ]]; then
    source ~/.zsh/env.local.zsh
fi

# Tavily API キー（検索API用）のテンプレート
# 使用方法：https://tavily.com でアカウント作成後、APIキーを取得
# export TAVILY_API_KEY="your_tavily_api_key_here"

# 他のAPIキーのテンプレート
# export OPENAI_API_KEY="your_openai_key_here"
# export ANTHROPIC_API_KEY="your_anthropic_key_here"
# export GITHUB_TOKEN="your_github_token_here"

# Tavily API キーが設定されていない場合の警告を無効化（オプション）
# web_search機能を使用しない場合は以下をコメントアウト
if [[ -z "$TAVILY_API_KEY" ]]; then
    # 空のキーを設定してエラーを回避（実際の検索は動作しません）
    export TAVILY_API_KEY="disabled"
fi

