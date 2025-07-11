# menu_orderフィルターによる管理メニュー位置修正

## 実装日
2025-07-11

## 背景
事業者一覧・詳細レイアウトが関連メニューの下部に表示されており、tsukizuki-web-settingsの`admin_menu_settings.php`で定義されているメニュー順序に従っていなかった。

## 問題の原因
- tsukizuki-web-settingsの`my_custom_menu_order`関数で、`layout_rental_providers`がdefaultケースに入り、オプションページ（`-options`）として処理されていた
- 実際はカスタム投稿タイプなので、`edit.php?post_type=`として処理される必要があった

## 設計意図
- tsukizuki-web-settingsプラグインを直接変更せず、add-rentacar-layoutsプラグイン側でフィルターを使って対応
- `menu_order`フィルターに高優先度（999）で介入し、正しい順序に修正
- サイト構成で設定されたインデックス順に従って表示

## 修正内容
### class-provider-list.php
- 55行目：`menu_order`フィルターをコンストラクタに追加
- 539-601行目：`fix_menu_order`メソッドを追加
  - サイト構成データを取得
  - `layout_rental_providers`を正しく`edit.php?post_type=`として処理
  - separator2の後にインデックス順で全レイアウトを再配置

## 副作用
- 特になし
- 他のレイアウトの順序も正しく維持される

## 関連ファイル
- `/var/www/local.its.wp-test/htdocs/shop/wp-content/plugins/add-rentacar-layouts/includes/class-provider-list.php`
- `/var/www/local.its.wp-test/htdocs/shop/wp-content/plugins/tsukizuki-web-settings/admin_page/admin_menu_settings.php`（参照のみ）