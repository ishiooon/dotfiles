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

### 新しい Mac での初期構成

まだ dotfiles を clone していない新しい Mac では、次のコマンドで初期構成を開始できます。

```bash
curl -fsSL https://raw.githubusercontent.com/ishiooon/dotfiles/main/.bin/bootstrap-macos.sh \
  -o /tmp/bootstrap-macos.sh
bash /tmp/bootstrap-macos.sh
```

このスクリプトは、Homebrew、シェル設定、Neovim、Treesitter 用の `tree-sitter-cli`、Starship、WezTerm、UDEV Gothic NF、JankyBorders、Karabiner-Elements、Codex の管理対象設定をまとめて導入します。Neovim のプラグインと PHP デバッグ拡張も初回に準備し、dotfiles を `~/dotfiles` に clone して設定をリンクします。既に `~/dotfiles` が Git リポジトリの場合はその内容を使用し、Git リポジトリではない既存ディレクトリは上書きせずに中断します。

zsh・Bash の起動時に Homebrew の標準配置先と `~/.bin` をコマンドの検索対象に加えるため、ターミナルを開き直しても導入したコマンドを使えます。初期構成が失敗した場合、JankyBorders の削除は今回新規導入を試みたものだけが対象で、既存の JankyBorders は削除しません。

導入前の手順確認には、次のドライランを使用できます。

```bash
bash /tmp/bootstrap-macos.sh --dry-run
```

すでに dotfiles を clone 済みで、設定リンクだけを再作成したい場合は次のコマンドを実行します。

```bash
bash ~/dotfiles/.bin/install.sh --env=localdev
```

この単独インストーラーにも `--dry-run` と失敗時の復元機能があります。

```bash
bash ~/dotfiles/.bin/install.sh --env=localdev --dry-run
```

この「設定をリンクする」とは、設定を二重にコピーするのではなく、ホームディレクトリから dotfiles 内の管理対象を参照することです。対象は次のとおりです。

- `~/.zshrc`、`~/.bashrc`、`.zsh`、`.bash`
- `~/.config`（Neovim、Starship、WezTerm、JankyBorders、Karabiner-Elements、lazygit）
- `~/.bin`、`~/.claude`、`~/.agents`
- `~/.codex/AGENTS.md`、`~/.codex/agents`（認証情報や履歴は対象外）

そのため、dotfiles 側の設定を更新すると各アプリケーションへ反映されます。既存の設定は `~/dotbackup/` へ退避します。

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

#### 4. JankyBorders のインストール
フォーカス中のウィンドウを枠線で見分けるため、JankyBorders の設定を dotfiles で管理します。設定の実体は `.config/borders/bordersrc` です。
導入前確認は `bash .bin/install-janky-borders.sh --dry-run`、導入は `bash .bin/install-janky-borders.sh`、設定変更後の再読み込みは `brew services restart borders` です。
導入時は `brew install felixkratz/formulae/borders` と配布元を含む名前を指定します。[Homebrew の信頼ルール](https://docs.brew.sh/Tap-Trust#installing-from-a-tap)に従い、JankyBorders の formula だけを信頼対象にします。

#### 5. Karabiner-Elements のインストール

Macの内蔵JISでは文字キーを上と外側へ移します。以下は移動前の物理キーで書いています。

| 物理キー | 動作 |
| --- | --- |
| `e` 長押し＋ `f` | 内蔵のキー一覧を表示 |
| `e` 長押し＋ `o` / `p` / `@` / `[` | 左 / 下 / 上 / 右 |
| `e` 長押し＋ `;` / `:` | 英数（ABC）/ かな（あいう） |
| `w` / `d` / `s` / `a` 長押し | 数字 / 記号 / ファンクションキー / メディア |

内蔵の右かなとスペースは短押しでスペース、長押しでShift。左英数と右Commandは短押しでEnter、長押しでCommand。左CommandはOptionとして使います。Command＋Tab中は、Commandを保持したまま物理 `e` と矢印に対応するキーを使います。

ほかの外付けキーボードでは従来の `f/d/v/c/x` レイヤーを使い、Fを保持してBを押すと外付け用のキー一覧が出ます。Toraboで同じ操作をすると専用のキー一覧が出ます。キー一覧はBに対応するキーを離すと閉じます。

内蔵・外付けの表示は [内蔵JISの定義](.config/karabiner/keymap-layers.json) と [外付けのレイヤー定義](.config/karabiner/keymap-layers-external.json) で管理します。[Karabinerの設定](.config/karabiner/karabiner.json) と同じ割り当てを反映してください。

導入前確認は `bash .bin/install-karabiner.sh --dry-run`、導入は `bash .bin/install-karabiner.sh` です。初回はシステム設定で Input Monitoring とアクセシビリティの許可が必要です。許可後に Karabiner-Elements を起動すると設定が有効になります。

更新前からキー一覧が起動している場合は、`~/.bin/karabiner-keymap-hud stop` で終了します。次の表示操作で新しい定義を読み込みます。

#### Torabo-tsuki (S) のキーマップ編集

キー割り当てとトラックボール、スリープ設定をリポジトリで管理します。GitHubで設定を編集して保存すると、右親機・左子機のファームウェアが自動でビルドされます。MacのKarabinerで表示するキー一覧にはToraboの配列も含まれます。[編集・ビルド・書き込み手順](.config/torabo-zmk/README.md)

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

.config/
├── borders/                # JankyBordersの設定
├── karabiner/              # Karabiner-Elements（f+hjkl→矢印）の設定
├── nvim/                   # Neovimの設定
├── wezterm/                # WezTermの設定
└── starship.toml           # starshipの設定
```

## テスト情報

ここはmainで書き換えました
