#!/bin/bash
# WordPress stubs インストールスクリプト

echo "Installing WordPress stubs for Intelephense..."

# Composerがインストールされているか確認
if ! command -v composer &> /dev/null; then
    echo "Composer is not installed. Please install Composer first."
    exit 1
fi

# 実行ディレクトリを確認
INSTALL_DIR="$HOME/.config/composer"

# Composer global でWordPress stubsをインストール
composer global require --dev php-stubs/wordpress-stubs php-stubs/wordpress-globals php-stubs/wordpress-tests-stubs

echo "WordPress stubs installed successfully!"
echo ""
echo "Add the following to your Intelephense includePaths:"
echo "  $HOME/.config/composer/vendor/php-stubs/wordpress-stubs"
echo "  $HOME/.config/composer/vendor/php-stubs/wordpress-globals" 
echo "  $HOME/.config/composer/vendor/php-stubs/wordpress-tests-stubs"