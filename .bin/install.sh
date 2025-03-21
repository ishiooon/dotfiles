# 初期インストール用スクリプト
# ===================================================
# 1. zshのインストール
# ===================================================
# $HOMEに.zshrcがある場合はdotbackupディレクトリを作成して.zshrcを退避
if [ -e $HOME/.zshrc ]; then
  echo "Backup .zshrc to $HOME/dotbackup"
  mkdir -p $HOME/dotbackup
  mv $HOME/.zshrc $HOME/dotbackup/.zshrc
fi

# .zshrcを$HOMEにシンボリックリンク
echo "Create symbolic link to $HOME/.zshrc"
ln -s $HOME/dotfiles/.zshrc $HOME/.zshrc


# ===================================================
# 2. bashのインストール
# ===================================================
# $HOMEに.bashrcがある場合はdotbackupディレクトリを作成して.bashrcを退避
if [ -e $HOME/.bashrc ]; then
  echo "Backup .bashrc to $HOME/dotbackup"
  mkdir -p $HOME/dotbackup
  mv $HOME/.bashrc $HOME/dotbackup/.bashrc
fi

# .bashrcを$HOMEにシンボリックリンク
echo "Create symbolic link to $HOME/.bashrc"
ln -s $HOME/dotfiles/.bashrc $HOME/.bashrc
