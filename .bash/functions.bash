# 関数定義ファイルを読み込む

# ~/.bash/functionsディレクトリのすべての.bashファイルを読み込む
for file in ~/.bash/functions/*.bash; do
  # ファイルが存在する場合のみ読み込む
  if [ -f "$file" ]; then
    source "$file"
  fi
done

