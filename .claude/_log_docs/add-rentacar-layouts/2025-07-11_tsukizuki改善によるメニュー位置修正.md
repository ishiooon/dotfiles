# tsukizuki-web-settingsプラグインの改善による管理メニュー位置修正

## 実装日
2025-07-11

## 背景
事業者一覧・詳細レイアウトの管理メニュー位置修正において、当初add-rentacar-layoutsプラグイン側で回避策を実装したが、tsukizuki-web-settingsプラグインを改善することでよりシンプルな解決策が実現できることが判明した。

## 設計意図
- tsukizuki-web-settingsにフィルターフックを追加し、カスタムレイアウトタイプの処理を拡張可能にする
- 後方互換性を保ちながら、新しいレイアウトタイプへの対応を容易にする
- 回避策を削除し、コードの保守性を向上

## 修正内容
### tsukizuki-web-settings/admin_page/admin_menu_settings.php
- 51-76行目：`my_custom_menu_order`関数を修正
  - `tsukizuki_admin_menu_item`フィルターを追加
  - カスタムレイアウトタイプの処理をフィルターで拡張可能に

### add-rentacar-layouts/includes/class-provider-list.php
- 55行目：`menu_order`フィルターを`tsukizuki_admin_menu_item`フィルターに変更
- 539-601行目：`fix_menu_order`メソッドを削除
- 539-552行目：`set_admin_menu_item`メソッドを新規追加
  - `layout_rental_providers`をカスタム投稿タイプとして処理

## 副作用
- 特になし
- 既存のレイアウトの動作に影響なし
- 新しいカスタムレイアウトの追加が容易に

## 関連ファイル
- `/var/www/local.its.wp-test/htdocs/shop/wp-content/plugins/tsukizuki-web-settings/admin_page/admin_menu_settings.php`
- `/var/www/local.its.wp-test/htdocs/shop/wp-content/plugins/add-rentacar-layouts/includes/class-provider-list.php`