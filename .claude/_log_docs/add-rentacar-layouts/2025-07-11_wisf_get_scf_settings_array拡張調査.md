# Add Rentacar Layouts - wisf_get_scf_settings_array 拡張調査

**実施日**: 2025-07-11  
**機能名**: カスタムレイアウトのSCF設定取得機能の調査と拡張提案  

## 実装の背景

`tsukizuki-web-settings` プラグインの `wisf_get_scf_settings_array` 関数がカスタムレイアウト（`layout_rental_members` など）に対応していないため、サイト構成からカスタムレイアウトが正しく処理されない問題の調査と解決策の提案。

## 問題分析

### 1. 現在の実装状況

#### wisf_get_scf_settings_array 関数
- **場所**: `/wp-content/plugins/tsukizuki-web-settings/use_scf/wp_its_scf_functions.php` (180-215行目)
- **問題点**:
  - ハードコードされた8つの標準レイアウトのみ対応
  - カスタムレイアウトの場合、空の配列を返す
  - 拡張用のフィルターフックが存在しない

#### 処理フローの不整合
```php
// create_pages関数内（111行目）
'scf_settings' => wisf_get_scf_settings_array($layout_style)

// カスタムレイアウトの場合、空の配列が返される
// → SCFフィールドが作成されない
```

### 2. add-rentacar-layouts の現在の回避策

プラグインは独自に `saam_create_scf_option_menu` を呼び出し、定数を直接渡している：
```php
// class-member-list.php (219-227行目)
saam_create_scf_option_menu([
    'page_name' => $page_name,
    'page_name_jp' => $page_title_with_number,
    'menu_index' => $this->layout_info['menu_position'],
    'scf_settings' => [
        LAYOUT_RENTAL_MEMBERS_CUSTOM_FIELDS_DATA_GROUP,
        LAYOUT_RENTAL_MEMBERS_PAGE_SETTINGS_GROUP
    ]
]);
```

## 設計意図

### 1. 最小限の修正で最大の効果
- tsukizuki-web-settingsへの修正を最小限に抑える
- 既存の処理を壊さない後方互換性の維持
- 将来の拡張性を確保

### 2. WordPressのベストプラクティスに準拠
- フィルターフックによる拡張性
- アクションフックによる処理の挿入
- 疎結合な設計

## 推奨解決策

### 1. wisf_get_scf_settings_array へのフィルター追加

```php
// フィルターフックの追加（213行目の前）
$settings = apply_filters('tsukizuki_scf_settings_array', $settings, $layout_style);
```

**効果**:
- 外部プラグインからカスタムレイアウトの設定を動的に追加可能
- 既存の処理に影響なし

### 2. create_pages 関数の拡張

```php
// カスタムレイアウトタイプの判定
$layout_types = apply_filters('tsukizuki_layout_types', []);
$is_custom_layout = isset($layout_types[$layout_style]);

// defaultケースの追加
default:
    $scf_settings = wisf_get_scf_settings_array($layout_style);
    if (!empty($scf_settings)) {
        // SCF設定を作成
    }
```

**効果**:
- 未知のレイアウトも処理可能
- カスタムレイアウトの動的処理

### 3. add-rentacar-layouts での実装

```php
// フィルターフックの利用
add_filter('tsukizuki_scf_settings_array', function($settings, $layout_style) {
    if ($layout_style === 'layout_rental_members') {
        $settings[] = LAYOUT_RENTAL_MEMBERS_CUSTOM_FIELDS_DATA_GROUP;
        $settings[] = LAYOUT_RENTAL_MEMBERS_PAGE_SETTINGS_GROUP;
    }
    return $settings;
}, 10, 2);
```

## 主要な修正ファイル

### tsukizuki-web-settings プラグイン（提案）
1. `use_scf/wp_its_scf_functions.php`
   - `wisf_get_scf_settings_array` 関数へのフィルター追加
   - `create_pages` 関数のdefaultケース追加

### add-rentacar-layouts プラグイン
1. `includes/class-layout-integration.php`
   - フィルターフックの実装追加

## 副作用・注意点

### 1. パフォーマンスへの影響
- **影響**: フィルター処理による軽微なオーバーヘッド
- **対策**: 必要な場合のみフィルターを適用

### 2. 設定の重複
- **懸念**: 直接的な方法とフィルター経由の両方で設定される可能性
- **対策**: 統一的な実装方法への移行

### 3. エラーハンドリング
- **課題**: カスタムレイアウトの設定が不正な場合の処理
- **対策**: 設定の検証とデフォルト値の提供

## 技術仕様

### フィルターフック仕様
```php
/**
 * tsukizuki_scf_settings_array
 * 
 * @param array $settings 現在の設定配列
 * @param string $layout_style レイアウトスタイル名
 * @return array 修正された設定配列
 */
apply_filters('tsukizuki_scf_settings_array', $settings, $layout_style);
```

### 実装ファイル
- `wisf_get_scf_settings_array_patch.php`: 修正提案コード
- `create_pages_custom_layout_patch.php`: create_pages関数の拡張提案
- `wisf_get_scf_settings_array_filter_example.php`: フィルター実装例

## 今後の改善計画

### Phase 1: 即時対応
- tsukizuki-web-settingsへのフィルター追加要望
- add-rentacar-layoutsでのフィルター実装

### Phase 2: 統合改善
- サイト構成からの統一的な処理フロー
- エラーハンドリングの強化

### Phase 3: 機能拡張
- カスタムレイアウトの動的登録API
- 設定のバリデーション機能
- デバッグモードの追加

## 完了状況

✅ `wisf_get_scf_settings_array` 関数の調査  
✅ 問題点の特定と分析  
✅ 解決策の設計と提案  
✅ 実装例の作成  
⏳ tsukizuki-web-settingsへの修正適用（要検討）  
⏳ add-rentacar-layoutsでのフィルター実装（予定）

## セキュリティ対策

- **入力値検証**: レイアウトスタイル名の検証
- **権限チェック**: 管理者権限の確認
- **データサニタイズ**: 設定配列の適切な処理

**実装品質**: 調査と提案により、カスタムレイアウトの統合的な処理方法が明確になりました。最小限の修正で最大の拡張性を実現する設計となっています。