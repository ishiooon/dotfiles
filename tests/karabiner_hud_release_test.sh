#!/usr/bin/env bash
set -euo pipefail

[[ "${1:-}" == --env=localdev ]] || { echo "--env=localdev を指定してください。" >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture="$(mktemp -d)"
fixture="$(cd "$fixture" && pwd -P)"
trap 'touch "$fixture/finish"; rm -rf "$fixture"' EXIT
launcher="$root/.bin/karabiner-keymap-hud"
export XDG_CACHE_HOME="$fixture/cache" HUD_TEST_FIXTURE="$fixture"
export BASH_ENV="$fixture/mock-shell" KARABINER_HUD_HIDUTIL="$fixture/hidutil"
export KARABINER_KEYMAP_HUD_JS="$fixture/mock-hud.js"
state="$XDG_CACHE_HOME/karabiner-keymap-hud"
mkdir -p "$state"
export HUD_TEST_PROCESS="/usr/bin/osascript -l JavaScript $KARABINER_KEYMAP_HUD_JS daemon $root/.config/karabiner/scripts/keymap-hud.html $root/.config/karabiner/keymap-layers.json $state/daemon.pid $state/command"

# 実機を検索せず、テストが明示的に許可した時点で接続結果を返す。
cat >"$KARABINER_HUD_HIDUTIL" <<'SH'
#!/usr/bin/env bash
touch "$HUD_TEST_FIXTURE/searching"
for attempt in {1..300}; do
  [[ -d "$HUD_TEST_FIXTURE" ]] || exit 1
  if [[ -f "$HUD_TEST_FIXTURE/search-complete" ]]; then
    printf '%s\n' '0xfeed 0xbcad 0x1 1 6 0x1 USB AppleUserHIDDevice Torabo-tsuki (null) 0'
    exit 0
  fi
  sleep 0.01
done
exit 1
SH
chmod +x "$KARABINER_HUD_HIDUTIL"
cat >"$BASH_ENV" <<'SH'
ps() { printf '%s\n' "$HUD_TEST_PROCESS"; }
kill() { [[ "$*" == '-0 12345' ]] || builtin kill "$@"; }
SH

# JXA は画面を作らず、起動を記録して許可が出るまで準備完了を待つ。
cat >"$KARABINER_KEYMAP_HUD_JS" <<'JS'
ObjC.import("Foundation");
function run(argv) {
  const pidPath = argv[3];
  const fixture = pidPath.replace(/\/cache\/karabiner-keymap-hud\/daemon\.pid$/, "");
  const files = $.NSFileManager.defaultManager;
  const pid = $.NSProcessInfo.processInfo.processIdentifier;
  const empty = $.NSData.data;
  const exists = (name) => files.fileExistsAtPath(`${fixture}/${name}`);
  files.createFileAtPathContentsAttributes(`${fixture}/daemon-${pid}`, empty, $.NSDictionary.dictionary);
  for (let attempt = 0; attempt < 300 && !exists("startup-complete") && !exists("finish"); attempt++) delay(0.01);
  if (exists("finish") || !exists("startup-complete")) return;
  $.NSString.stringWithString(`${pid}\n`).writeToFileAtomicallyEncodingError(pidPath, true, $.NSUTF8StringEncoding, null);
  for (let attempt = 0; attempt < 500 && exists("startup-complete") && !exists("finish"); attempt++) delay(0.01);
}
JS

python3 - "$launcher" "$fixture" "$state" <<'PY'
import subprocess
import sys
import time
from pathlib import Path

launcher, fixture, state = map(Path, sys.argv[1:])

def launch(*args):
    return subprocess.Popen(["bash", launcher, *args])

def call(*args):
    subprocess.run(["bash", launcher, *args], check=True, timeout=10)

def wait_for(check):
    deadline = time.monotonic() + 8
    while not check():
        if time.monotonic() >= deadline:
            log = state / "hud.log"
            raise AssertionError(f"テスト用プロセスからの準備完了を確認できませんでした。\n{log.read_text() if log.exists() else ''}")
        time.sleep(0.01)

def command():
    return (state / "command").read_text().splitlines()[0]

def finish(process):
    assert process.wait(timeout=10) == 0

(state / "daemon.pid").write_text("12345\n")
show = launch("show")
wait_for((fixture / "searching").exists)
call("hide")
(fixture / "search-complete").touch()
finish(show)
assert command() == "hide", "遅れて機器検索が終わると、キーを離した後に表示してしまいます。"

(state / "daemon.pid").unlink()
first = launch("show", "jis")
wait_for(lambda: list(fixture.glob("daemon-*")))
second = launch("show", "external")
wait_for(lambda: command() == "show external")
call("hide")
(fixture / "startup-complete").touch()
finish(first)
finish(second)
wait_for((state / "daemon.pid").exists)
assert command() == "hide", "起動完了後に、キーを離した後の非表示が取り消されました。"
assert len(list(fixture.glob("daemon-*"))) == 1, "同じキー一覧が同時に複数起動しました。"
(fixture / "finish").touch()
PY

printf '%s\n' '成功: 起動や機器検索が遅れても、キー一覧はキー解放後に表示されません。'
