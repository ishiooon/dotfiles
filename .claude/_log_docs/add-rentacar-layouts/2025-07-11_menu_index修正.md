# 管理メニュー表示順序の修正

## 実装日
2025-07-11

## 背景
add-rentacar-layoutsプラグインで追加される「加盟事業者一覧」レイアウトの管理メニューが、サイト構成で設定したインデックス順ではなく、関連メニューの下部に表示されていた。

## 問題の原因
- `class-member-list.php`で`menu_index`パラメータに不適切な値（70 + インデックス）を設定していた
- SCFの`saam_create_scf_option_menu`関数で使用される`menu_index`は、WordPressの`menu_position`とは異なる内部的な値

## 設計意図
- tsukizuki-web-settingsプラグインの標準的なメニュー順序に従う
- トップページ（menu_index=1）、お問い合わせ（menu_index=2）の後に、ページインデックス順で配置

## 修正内容
### class-member-list.php
- 217行目：`menu_index`を`$this->layout_info['page_index'] + 3`に修正
- 407行目：`menu_index`を`$page_data['index'] + 3`に修正

### class-provider-list.php
- 修正不要（投稿タイプは`menu_position`を使用しており、70番台が適切）

## 副作用
- 特になし

## 関連ファイル
- `/var/www/local.its.wp-test/htdocs/shop/wp-content/plugins/add-rentacar-layouts/includes/class-member-list.php`
- `/var/www/local.its.wp-test/htdocs/shop/wp-content/plugins/add-rentacar-layouts/includes/class-provider-list.php`