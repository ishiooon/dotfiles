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

# ===================================================
# 3. startshipの設定
# ===================================================
# $HOMEに.config/.starship.tomlがある場合はdotbackupディレクトリを作成して.config/.starship.tomlを退避
if [ -e $HOME/.config/starship.toml ]; then
  echo "Backup .config/starship.toml to $HOME/dotbackup"
  mkdir -p $HOME/dotbackup
  mv $HOME/.config/starship.toml $HOME/dotbackup/starship.toml
fi
# .config/.starship.tomlを$HOMEにシンボリックリンク
echo "Create symbolic link to $HOME/.config/starship.toml"
ln -s $HOME/dotfiles/.config/starship.toml $HOME/.config/starship.toml
