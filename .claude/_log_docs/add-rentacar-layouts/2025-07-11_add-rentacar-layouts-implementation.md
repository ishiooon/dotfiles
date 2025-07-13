# Add Rentacar Layoutsプラグイン実装

## 実装日時
2025-07-11

## 実装の背景
WordPressサイトでレンタカー協会用の新しいレイアウト機能を追加するため、tsukizuki-web-settingsを拡張するプラグインを作成しました。管理メニューが正しく表示されない問題を解決し、サイト構成からの統一的な管理を実現しました。

## 設計意図
- **モジュラー設計**: 各レイアウトを独立したクラスとして実装
- **tsukizuki-web-settings連携**: 既存プラグインのフック機構を活用
- **拡張性**: 将来的な機能追加を容易にする構造
- **WordPress標準準拠**: コーディング規約とベストプラクティスに従う

## 実装内容

### 1. プラグイン構造
```
add-rentacar-layouts/
├── add-rentacar-layouts.php      # メインファイル
├── includes/
│   ├── class-layout-integration.php  # レイアウト統合
│   ├── class-member-list.php         # 加盟事業者一覧
│   ├── class-provider-list.php       # 事業者一覧・詳細
│   ├── class-admin-menu.php          # 管理メニュー
│   └── class-shortcodes.php          # ショートコード
├── config/
│   ├── layout_rental_members.php     # 加盟事業者設定
│   └── layout_rental_providers.php   # 事業者一覧設定
├── common_functions/
│   └── layouts/
│       └── layout_rental_members.php  # レイアウト表示関数
├── templates/                        # フロントエンドテンプレート
└── assets/                          # CSS/JSファイル
```

### 2. 主要機能

#### 加盟事業者一覧（layout_rental_members）
- 固定ページとして実装
- SCFでのフィールド管理
- フリガナ自動生成機能（予定）
- あかさたなアンカージャンプ（予定）

#### 事業者一覧・詳細（layout_rental_provider）
- カスタム投稿タイプとして実装
- エリア・車両タクソノミー
- OR検索機能（予定）
- 個別詳細ページ

### 3. tsukizuki-web-settingsとの連携

#### フィルターフック実装
- `tsukizuki_layout_styles`: レイアウトスタイルの追加
- `tsukizuki_layout_types`: レイアウトタイプの定義
- `tsukizuki_scf_settings_array`: SCF設定の追加
- `tsukizuki_create_custom_layout_page`: ページ作成処理

## 副作用
- 管理画面にレンタカー協会設定メニューが追加される
- サイト構成で2つの新しいレイアウトが選択可能になる
- データベースに新しいオプションが保存される

## 関連ファイル

### 新規作成ファイル
- `/wp-content/plugins/add-rentacar-layouts/` 配下の全ファイル

### 修正ファイル（tsukizuki-web-settings）
- `/wp-content/plugins/tsukizuki-web-settings/use_scf/wp_its_scf_functions.php`
  - `wisf_get_scf_settings_array`関数にフィルターフック追加
  - `create_pages`関数にdefaultケース追加

### ドキュメント
- `/var/www/local.its.wp-test/htdocs/shop/CLAUDE.md`
  - 新しいフィルターフックの文書化

## 今後の課題
1. フロントエンド表示機能の実装
2. 検索・フィルタリング機能の実装
3. フリガナ自動生成API連携
4. アンカージャンプナビゲーション
5. レスポンシブデザイン対応
6. パフォーマンス最適化

## 更新履歴
### 2025-07-11 追加修正
- 事業者一覧・詳細レイアウトのメニュー表示を修正
- レイアウトスタイル名を`layout_rental_providers`から`layout_rental_provider`に修正
- カスタム投稿タイプのメニュー名にインデックス番号を追加
- 不要なテストメニューを削除し、設定サブメニューのみを追加するように変更

### 2025-07-11 追加修正2
- カスタム投稿タイプの`show_in_menu`をfalseに設定し、自動メニューを無効化
- 独自のメニューを作成し、インデックス番号付きタイトルを正しく表示
- サブメニューとして「事業者一覧」「新規追加」「表示設定」を追加
- 不要になった`modify_menu_label`メソッドを削除

### 2025-07-11 追加修正3 - tsukizuki-web-settings標準方式への移行
- 固定の`POST_TYPE`定数を動的な`$post_type`変数に変更
- `ccpp_create_new_post`を使用してtsukizuki-web-settingsの標準的な方法でカスタム投稿タイプを作成
- `handle_custom_layout_page`フィルター内でカスタム投稿タイプとカスタムフィールドを定義
- 不要な`register_post_type`、`add_admin_menu`、`check_and_add_menu`メソッドを削除
- カスタムフィールドの定義をインラインで実装（tsukizuki-web-settingsと同じ方式）

### 2025-07-11 追加修正4 - タイミング問題の修正
- `register_post_types_early`メソッドを追加し、`init`アクションのpriority 10で実行
- `ccpp_create_new_post`が遅いタイミング（priority 99）で実行される問題を解決
- サイト構成データを直接`get_option`で取得して早いタイミングでカスタム投稿タイプを登録

### 2025-07-11 追加修正5 - レイアウトスタイル名の修正
- レイアウトスタイル名を`layout_rental_provider`（単数形）から`layout_rental_providers`（複数形）に統一
- tsukizuki-web-settingsから呼び出される際のレイアウトスタイル名が複数形であることが判明
- すべての条件文とチェック処理を複数形に修正

### 2025-07-11 追加修正6 - SCFデータ取得方法の修正
- `get_option('site_structure-options')`がfalseを返す問題を修正
- `SCF::get_option_meta`を使用してサイト構成データを正しく取得
- 直接`register_post_type`を使用してカスタム投稿タイプを登録
- デバッグコードをすべて削除してクリーンアップ

### 2025-07-11 追加修正7 - tsukizuki-web-settingsのフィルターフック内で処理
- `register_post_types_early`メソッドを削除
- `handle_custom_layout_page`フィルター内で`ccpp_create_new_post`を使用
- ブログレイアウトと同じ処理方法に統一
- タクソノミー登録をinitフックで処理

### 2025-07-11 追加修正8 - フィルター登録タイミングの修正
- tsukizuki-web-settingsが`init` priority 99で`wisf_create_custom_page()`を実行することを発見
- プラグインのクラスインスタンス化を`plugins_loaded`フックで実行するように変更
- これによりフィルターがtsukizuki-web-settingsの処理前に確実に登録される
- デバッグログを追加して処理フローを確認

### 2025-07-11 追加修正9 - メニュー並び順の修正
- `ccpp_create_new_post`が固定のmenu_position(5)を使用していることが判明
- 直接`register_post_type`を使用してmenu_positionを制御
- `menu_position = 70 + $page_data['index']`で他のtsukizuki-web-settingsメニューと同じ位置計算
- カテゴリタクソノミーも同時に登録してtsukizuki-web-settingsと同じ動作を実現