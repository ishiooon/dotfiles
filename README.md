# dotfiles

## 初回インストール

### 自動インストール（推奨）

提供されているインストールスクリプトを使用して、一括でセットアップを行えます：

```bash
# dotfilesディレクトリに移動
cd ~/dotfiles

# インストールスクリプトを実行
bash .bin/install.sh
```

### 手動インストール

インストールスクリプトを使用せず、手動でセットアップする場合：

#### 1. シェル設定ファイルのシンボリックリンク作成

**既存ファイルのバックアップ（必要に応じて）：**
```bash
mkdir -p ~/dotbackup
# .zshrcがある場合
mv ~/.zshrc ~/dotbackup/.zshrc
# .bashrcがある場合  
mv ~/.bashrc ~/dotbackup/.bashrc
```

**シンボリックリンクの作成：**
```bash
# zsh設定
ln -s ~/dotfiles/.zshrc ~/.zshrc

# bash設定
ln -s ~/dotfiles/.bashrc ~/.bashrc
```

#### 2. starship設定のシンボリックリンク作成

```bash
# 既存設定をバックアップ（必要に応じて）
mv ~/.config/starship.toml ~/dotbackup/starship.toml

# シンボリックリンク作成
ln -s ~/dotfiles/.config/starship.toml ~/.config/starship.toml
```

#### 3. mcphub設定のシンボリックリンク作成

```bash
# 既存設定をバックアップ（必要に応じて）
mv ~/.config/mcphub ~/dotbackup/mcphub

# シンボリックリンク作成
ln -s ~/dotfiles/.config/mcphub ~/.config/mcphub
```

## セットアップ

### APIキーの設定

このdotfilesには、APIキーなどの機密情報を安全に管理するシステムが含まれています。

#### 初回セットアップ

**bash使用者の場合：**
1. ローカル環境変数ファイルを作成：
   ```bash
   cp ~/.bash/env.local.bash.example ~/.bash/env.local.bash
   ```

2. 作成したファイルを編集して実際のAPIキーを設定：
   ```bash
   nano ~/.bash/env.local.bash
   ```

3. 新しいターミナルセッションを開くか、設定を再読み込み：
   ```bash
   source ~/.bashrc
   ```

**zsh使用者の場合：**
1. ローカル環境変数ファイルを作成：
   ```zsh
   cp ~/.zsh/env.local.zsh.example ~/.zsh/env.local.zsh
   ```

2. 作成したファイルを編集して実際のAPIキーを設定：
   ```zsh
   nano ~/.zsh/env.local.zsh
   ```

3. 新しいターミナルセッションを開くか、設定を再読み込み：
   ```zsh
   source ~/.zshrc
   ```

#### 対応APIサービス

- **Tavily** (検索API) - https://tavily.com
- **OpenAI** (GPT API) - https://platform.openai.com
- **Anthropic** (Claude API) - https://console.anthropic.com
- **GitHub** (Personal Access Token) - https://github.com/settings/tokens

#### セキュリティ

- `.bash/env.local.bash` と `.zsh/env.local.zsh` は自動的に`.gitignore`で除外されます
- 実際のAPIキーがgitリポジトリにコミットされることはありません
- `.bash/env.local.bash.example` と `.zsh/env.local.zsh.example` がテンプレートとして提供されます

## ファイル構造

```
.bash/
├── env.bash                 # 環境変数テンプレート（gitで管理）
├── env.local.bash.example   # ローカル設定例（gitで管理）
├── env.local.bash          # 実際のローカル設定（gitで除外）
├── history.bash            # 履歴設定
├── aliases.bash            # エイリアス定義
├── functions.bash          # 関数定義
├── terminal.bash           # ターミナル設定
├── completion.bash         # 補完設定
└── starship.bash           # starship設定

.zsh/
├── env.zsh                  # 環境変数テンプレート（gitで管理）
├── env.local.zsh.example    # ローカル設定例（gitで管理）
├── env.local.zsh           # 実際のローカル設定（gitで除外）
├── history.zsh             # 履歴設定
├── keybindings.zsh         # キーバインディング設定
└── functions.zsh           # 関数定義
```
