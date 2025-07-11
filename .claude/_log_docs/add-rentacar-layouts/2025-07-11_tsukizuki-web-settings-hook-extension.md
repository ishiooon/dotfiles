# tsukizuki-web-settingsフック拡張実装

## 実装日時
2025-07-11

## 実装の背景
サイト構成で追加した「加盟事業者一覧」レイアウトページが管理メニューに表示されない問題を解決するため、tsukizuki-web-settingsプラグインに最小限の拡張ポイントを追加しました。

## 設計意図
- **後方互換性の完全維持**: 既存のレイアウトや機能に一切影響を与えない
- **拡張性の提供**: 外部プラグインからカスタムレイアウトを追加できるフィルターフックを実装
- **最小限の変更**: tsukizuki-web-settingsへの変更を最小限に抑え、保守性を確保

## 実装内容

### 1. tsukizuki-web-settingsへの追加

#### wisf_get_scf_settings_array関数への拡張 (wp_its_scf_functions.php:215-217)
```php
// カスタムレイアウト用のフィルターフック（後方互換性を保持）
$settings = apply_filters('tsukizuki_scf_settings_array', $settings, $layout_style);
```

#### create_pages関数へのdefaultケース追加 (wp_its_scf_functions.php:174-189)
```php
default:
    // カスタムレイアウト用のフィルターフック（後方互換性を保持）
    $custom_layout_handled = apply_filters('tsukizuki_create_custom_layout_page', false, $layout_style, [
        'page_name' => $page_name,
        'page_name_jp' => $page_name_jp,
        'page_title' => $page_title,
        'plan' => $plan,
        'index' => $i,
        'structure_data' => $target_page
    ]);
    
    // カスタムレイアウトがフィルターで処理されなかった場合の警告（開発支援用）
    if (!$custom_layout_handled && WP_DEBUG) {
        error_log('Unknown layout style: ' . $layout_style);
    }
    break;
```

### 2. add-rentacar-layoutsでのフィルター実装

#### class-member-list.phpへの追加
- `tsukizuki_scf_settings_array`フィルターの実装
- `tsukizuki_create_custom_layout_page`フィルターの実装

#### class-provider-list.phpへの追加
- 同様のフィルター実装（カスタム投稿タイプ対応）

## 副作用
- なし（既存機能への影響はありません）

## 関連ファイル
- `/wp-content/plugins/tsukizuki-web-settings/use_scf/wp_its_scf_functions.php`
- `/wp-content/plugins/add-rentacar-layouts/includes/class-member-list.php`
- `/wp-content/plugins/add-rentacar-layouts/includes/class-provider-list.php`
- `/wp-content/plugins/add-rentacar-layouts/config/layout_rental_members.php`
- `/wp-content/plugins/add-rentacar-layouts/config/layout_rental_providers.php`

## 今後の課題
- カスタムレイアウトのフロントエンド表示実装
- SCFフィールドのJavaScript連携（フリガナ自動生成など）
- 検索機能の実装（事業者一覧）