#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "このテストは --env=localdev を指定してください。" >&2
  exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

# 起動済みの常駐プログラムと機器一覧を再現し、実際の機器やプロセスには触れない。
export XDG_CACHE_HOME="$fixture/cache"
export KARABINER_HUD_HIDUTIL="$fixture/hidutil"
export BASH_ENV="$fixture/mock-processes"
state_dir="$XDG_CACHE_HOME/karabiner-keymap-hud"
mkdir -p "$state_dir"
printf '12345\n' > "$state_dir/daemon.pid"
printf 'idle\n' > "$state_dir/command"
export HUD_TEST_PROCESS="/usr/bin/osascript -l JavaScript $root/.config/karabiner/scripts/keymap-hud.js daemon $root/.config/karabiner/scripts/keymap-hud.html $root/.config/karabiner/keymap-layers.json $state_dir/daemon.pid $state_dir/command"
cat > "$BASH_ENV" <<'MOCK'
kill() { [[ "$*" == '-0 12345' ]]; }
ps() { printf '%s\n' "$HUD_TEST_PROCESS"; }
MOCK
cat > "$KARABINER_HUD_HIDUTIL" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
# 対象の機器番号とキーボード用途を指定したときだけ、一覧取得が成功する。
[[ $# -eq 3 && "$1" == list && "$2" == --matching &&
   "$3" == *'"VendorID":65261'* && "$3" == *'"ProductID":48301'* &&
   "$3" == *'"PrimaryUsagePage":1'* && "$3" == *'"PrimaryUsage":6'* ]]

printf '%s\n' 'Devices:' 'VendorID ProductID LocationID UsagePage Usage RegistryID Transport Class Product UserClass Built-In'
case "$HUD_TEST_DEVICES" in
  usb|both|failure)
    printf '%s\n' '0xfeed 0xbcad 0x1 1 6 0x1 USB AppleUserHIDDevice Torabo-tsuki (null) 0'
    ;;
  unrelated)
    printf '%s\n' '0xfeed 0xbcad 0x1 1 2 0x1 USB AppleUserHIDDevice Torabo-tsuki (null) 0' \
      '0xfeed 0xbcae 0x2 1 6 0x2 USB AppleUserHIDDevice Other (null) 0'
    ;;
esac
case "$HUD_TEST_DEVICES" in
  ble|both)
    printf '%s\n' '0xfeed 0xbcad 0x2 1 6 0x2 Bluetooth Low Energy IOHIDUserDevice Torabo-tsuki (null) 0'
    ;;
  failure)
    exit 1
    ;;
esac
MOCK
chmod +x "$KARABINER_HUD_HIDUTIL"

# 連続した表示操作で、接続・切断や取得失敗が毎回の表示先に反映される。
launcher="$root/.bin/karabiner-keymap-hud"
display_command() { head -n 1 "$state_dir/command"; }
expect_display() {
  local devices="$1" expected="$2" actual
  HUD_TEST_DEVICES="$devices" bash "$launcher" show
  actual="$(display_command)"
  if [[ "$actual" != "$expected" ]]; then
    printf '機器一覧が %s の場合の表示指示は %s のはずですが、%s でした。\n' "$devices" "$expected" "$actual" >&2
    exit 1
  fi
}

expect_display disconnected show
expect_display usb 'show torabo'
expect_display ble 'show torabo'
expect_display both 'show torabo'
expect_display unrelated show
expect_display failure show
expect_display disconnected show
KARABINER_HUD_HIDUTIL="$fixture/見つからない" expect_display usb show

# Mac の f+b 相当（show jis）は Torabo 接続中でもデーモンへは show（JIS）を渡す
HUD_TEST_DEVICES=usb bash "$launcher" show jis
[[ "$(display_command)" == show ]] || {
  echo "show jis が Torabo 接続中でもデーモン向け show になりません。" >&2
  exit 1
}
HUD_TEST_DEVICES=disconnected bash "$launcher" show torabo
[[ "$(display_command)" == 'show torabo' ]] || {
  echo "show torabo が未接続でも Torabo 指定になりません。" >&2
  exit 1
}

# 外付けの旧配列はTorabo接続中でも外付け専用の表示指示を渡す。
HUD_TEST_DEVICES=usb bash "$launcher" show external
[[ "$(display_command)" == 'show external' ]]

bash "$launcher" hide
[[ "$(display_command)" == hide ]]
[[ "$(bash "$launcher" status)" == 'running pid=12345 cmd=hide' ]]

# 同じランチャーを ~/.bin と配置元のどちらから呼んでも、起動済みの画面を参照する。
ln -s "$root/.bin" "$fixture/linked-bin"
[[ "$(bash "$fixture/linked-bin/karabiner-keymap-hud" status)" == 'running pid=12345 cmd=hide' ]] || exit 1

# ~/.config の設定がシンボリックリンクでも、配置元で実行中の画面を引き継ぐ。
ln -s "$root/.config/karabiner" "$fixture/linked-config"
KARABINER_KEYMAP_HUD_JS="$fixture/linked-config/scripts/keymap-hud.js" \
  KARABINER_KEYMAP_HUD_HTML="$fixture/linked-config/scripts/keymap-hud.html" \
  KARABINER_KEYMAP_LAYERS_JSON="$fixture/linked-config/keymap-layers.json" \
  bash "$launcher" status | grep -Fxq 'running pid=12345 cmd=hide'
printf '%s\n' '成功: Toraboの接続時は専用表示を選び、切断・取得失敗時は内蔵表示を維持します。'
