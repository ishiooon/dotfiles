# 関数定義ファイルを読み込む

# .zsh/functionsディレクトリのすべての.zshファイルを読み込む
for file in ~/.zsh/functions/*.zsh; do
  source "$file"
done

# エイリアス定義
# 履歴をクリーンアップするエイリアス
alias clean-history='~/.bin/clean_history.sh'

