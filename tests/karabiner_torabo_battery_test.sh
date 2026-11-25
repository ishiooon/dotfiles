#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--env=localdev" ]]; then
  printf '%s\n' '--env=localdev を指定してください。' >&2
  exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="$(mktemp -d)"
trap 'touch "$fixture/release"; rm -rf "$fixture"' EXIT
export XDG_CACHE_HOME="$fixture/cache"
export HUD_TEST_FIXTURE="$fixture"
export BASH_ENV="$fixture/mock-shell"
export KARABINER_HUD_HIDUTIL="$fixture/hidutil"
state="$XDG_CACHE_HOME/karabiner-keymap-hud"
mkdir -p "$state"
printf '12345\n' >"$state/daemon.pid"
printf 'idle\n' >"$state/command"
export HUD_TEST_PROCESS="/usr/bin/osascript -l JavaScript $root/.config/karabiner/scripts/keymap-hud.js daemon $root/.config/karabiner/scripts/keymap-hud.html $root/.config/karabiner/keymap-layers.json $state/daemon.pid $state/command"

# 起動済みのHUDと遅いコンパイラーを模擬し、macOSの画面や実機には触れない。
# 絶対パス呼び出しを避けるため、swiftc / codesign は PATH 上のスタブにする。
mkdir -p "$fixture/bin"
cat >"$fixture/bin/swiftc" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
# -o の直後だけを出力先にする（末尾の Info.plist 引数と取り違えない）。
out=""
prev=""
for arg; do
  if [[ "$prev" == "-o" ]]; then out="$arg"; fi
  prev="$arg"
done
[[ -n "$out" ]] || exit 1
printf 'compile\n' >>"$HUD_TEST_FIXTURE/compilations"
for attempt in {1..100}; do
  [[ ! -d "$HUD_TEST_FIXTURE" ]] && exit 1
  [[ -f "$HUD_TEST_FIXTURE/release" ]] && break
  sleep 0.05
done
[[ -f "$HUD_TEST_FIXTURE/release" ]] || exit 1
cat >"$out" <<'READER'
#!/usr/bin/env bash
printf 'read\n' >>"$HUD_TEST_FIXTURE/reads"
printf '%s\n' '{"right":80,"left":30}'
READER
chmod +x "$out"
SH
cat >"$fixture/bin/codesign" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$fixture/bin/swiftc" "$fixture/bin/codesign"
export PATH="$fixture/bin:$PATH"
cat >"$BASH_ENV" <<'SH'
kill() { [[ "$*" == '-0 12345' ]]; }
ps() { printf '%s\n' "$HUD_TEST_PROCESS"; }
SH
cat >"$KARABINER_HUD_HIDUTIL" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '0xfeed 0xbcad 0x2 1 6 0x2 Bluetooth Low Energy IOHIDUserDevice Torabo-tsuki S (null) 0'
SH
chmod +x "$KARABINER_HUD_HIDUTIL"

python3 - "$root/.bin/karabiner-keymap-hud" "$fixture" "$state" <<'PY'
import json
import subprocess
import sys
import time
from pathlib import Path

launcher, fixture, state = map(Path, sys.argv[1:])

def call(command):
    subprocess.run(["bash", launcher, command], check=True, timeout=2)

def wait_for(path):
    end = time.monotonic() + 5
    while not path.exists():
        assert time.monotonic() < end, path
        time.sleep(0.05)

# コンパイル待ちの状態でも表示が戻り、同じ残量取得が並走しないことを確認する。
call("show")
assert (state / "command").read_text() == "show torabo\n"
wait_for(fixture / "compilations")
call("show")
call("hide")
assert (state / "command").read_text() == "hide\n"
(fixture / "release").touch()
result = state / "torabo-battery.json"
wait_for(result)
assert json.loads(result.read_text()) == {"right": 80, "left": 30}
assert (fixture / "compilations").read_text() == "compile\n"
assert (fixture / "reads").read_text() == "read\n"
assert (state / "command").read_text() == "hide\n"
PY

# 実機を使わず、GATTの特性表示形式に基づいて左右を判別する。
if [[ "$(uname -s)" == Darwin ]]; then
  sed '/^let reader = Reader()/,$d' "$root/.config/karabiner/scripts/torabo-battery.swift" >"$fixture/Battery.swift"
  cat >"$fixture/main.swift" <<'SWIFT'
import Foundation

let main = Data([0x04, 0, 0xad, 0x27, 1, 6, 1])
let auxiliary = Data([0x04, 0, 0xad, 0x27, 1, 8, 1])
precondition(batterySide(format: main) == .right)
precondition(batterySide(format: auxiliary) == .left)
precondition(batterySide(format: main.dropLast()) == nil)
precondition(batterySide(format: Data([0x04, 0, 0xad, 0x27, 2, 8, 1])) == nil)

var levels = BatteryLevels()
levels.record(Data([30]), side: .left)
levels.record(Data([80]), side: .right)
precondition(levels.values == ["right": 80, "left": 30])
levels.record(Data([101]), side: .right)
precondition(levels.values["right"] == 80)
levels.record(Data([75]), side: .right)
precondition(levels.values == ["left": 30])
var disconnected = BatteryLevels()
disconnected.record(Data([0]), side: .left)
precondition(disconnected.values.isEmpty)
SWIFT
  /usr/bin/swiftc -module-cache-path "$fixture/swift-cache" "$fixture/Battery.swift" "$fixture/main.swift" -o "$fixture/test-battery"
  "$fixture/test-battery"
fi

printf '%s\n' '成功: 残量取得はHUDの表示を待たせず、電池残量は応答の順序に関係なく左右を判別します。'
