#!/usr/bin/env bash
set -euo pipefail

# 実際の画面を操作せず、表示指示と設定の読み取りを検証する。
[[ "${1:-}" == --env=localdev ]] || { echo "--env=localdev を指定してください。" >&2; exit 2; }
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
node - "$root" <<'JS'
const fs = require("node:fs");
const vm = require("node:vm");
const assert = require("node:assert/strict");
const root = process.argv[2];
const source = fs.readFileSync(root + "/.config/karabiner/scripts/keymap-hud.js", "utf8");
const sandbox = vm.createContext({ ObjC: { import() {} } });
vm.runInContext(source, sandbox);
let definition = '{"model":"Torabo </script>"}';
sandbox.readText = () => definition;
const calls = [];
const browser = vm.createContext({
  window: { showKeymap: (profile, layers) => calls.push({ profile, layers: layers && JSON.stringify(layers) }) },
  buildToraboKeymap: (config) => ({ name: config.model })
});
vm.runInContext(sandbox.keymapDisplayScript("show torabo", "torabo-tsuki-s.json"), browser);
assert.equal(calls.at(-1).profile, "torabo");
assert.equal(browser.window.__TORABO_KEYMAP__.name, "Torabo </script>");
vm.runInContext(sandbox.keymapDisplayScript("show", "torabo-tsuki-s.json"), browser);
assert.equal(calls.at(-1).profile, "jis");
vm.runInContext(sandbox.keymapDisplayScript("show jis", "torabo-tsuki-s.json"), browser);
assert.equal(calls.at(-1).profile, "jis");
// 外付けでFを保持した場合は、従来のFレイヤーを内蔵の定義から独立して渡す。
const external = fs.readFileSync(root + "/.config/karabiner/keymap-layers-external.json", "utf8");
sandbox.readText = (path) => {
  assert.equal(path, "keymap-layers-external.json");
  return external;
};
vm.runInContext(sandbox.keymapDisplayScript("show external", "torabo-tsuki-s.json"), browser);
assert.deepEqual(calls.at(-1), { profile: "external", layers: JSON.stringify(JSON.parse(external)) });
definition = "設定が壊れている";
sandbox.readText = () => definition;
vm.runInContext(sandbox.keymapDisplayScript("show torabo", "torabo-tsuki-s.json"), browser);
assert.equal(calls.at(-1).profile, "jis");
const html = sandbox.buildHtmlDocument("<head></head>", '{"label":"</script>"}', "function buildToraboKeymap() {}");
assert.equal((html.match(/<\/script>/g) || []).length, 2);

// Cocoa の画面と WebView の完了通知を模擬し、保留中にキーを離した場合を再現する。
const timerCallbacks = [];
const webCallbacks = [];
const writes = [];
let command = "show\nrequest-1\n";
let opened = 0;
let closed = 0;
const configuration = { alloc: { init: {} } };
const panel = {
  setLevel() {}, setAlphaValue() {}, setOpaque() {}, setBackgroundColor() {}, setHasShadow() {},
  setIgnoresMouseEvents() {}, setCollectionBehavior() {}, setContentView() {},
  get orderFrontRegardless() { opened++; }, orderOut() { closed++; }
};
const webView = {
  setValueForKey() {}, setOpaque() {}, loadHTMLStringBaseURL() {},
  evaluateJavaScriptCompletionHandler(_, callback) { webCallbacks.push(callback); }
};
sandbox.$ = {
  NSProcessInfo: { processInfo: { processIdentifier: 12 } },
  NSApplication: { sharedApplication: { setActivationPolicy() {}, run() {} } },
  NSPanel: { alloc: { initWithContentRectStyleMaskBackingDefer() { return panel; } } },
  NSColor: { clearColor: {} }, NSMakeRect() {},
  WKWebViewConfiguration: configuration,
  WKWebView: { alloc: { initWithFrameConfiguration() { return webView; } } },
  NSURL: { URLWithString() {} },
  NSTimer: { scheduledTimerWithTimeIntervalRepeatsBlock(_, __, callback) { timerCallbacks.push(callback); } }
};
sandbox.readText = (path) => ({ html: "<head></head>", layers: "[]", command })[path] || "";
sandbox.writeText = (path, text) => writes.push([path, text]);
sandbox.run(["daemon", "html", "layers", "pid", "command"]);
assert.deepEqual(writes, [["pid", "12\n"]]);
command = "hide\nrequest-2\n";
webCallbacks.shift()();
assert.equal(opened, 0, "次の監視時刻より先に描画が完了しても、キー解放後は表示しません。");
timerCallbacks.shift()();
assert.equal(closed, 2);
assert.deepEqual(writes, [["pid", "12\n"]], "非表示の指示をほかのプロセスからも読める状態に保ちます。");

// 同じ配列を開き直すときは、直前に閉じた表示の完了通知を無視する。
command = "show\nrequest-3\n";
timerCallbacks.shift()();
command = "hide\nrequest-4\n";
timerCallbacks.shift()();
command = "show\nrequest-5\n";
timerCallbacks.shift()();
webCallbacks.shift()();
assert.equal(opened, 0);
// JXA では WebView のエラーなしを表す Objective-C の nil も真として評価される。
webCallbacks.shift()(null, { isNil: () => true });
assert.equal(opened, 1);

// 初回描画に失敗した場合は、同じ指示が最新である間だけ次の監視で描画し直す。
command = "show external\nrequest-6\n";
timerCallbacks.shift()();
webCallbacks.shift()(null, { isNil: () => false });
assert.equal(opened, 1);
timerCallbacks.shift()();
webCallbacks.shift()(null, { isNil: () => true });
assert.equal(opened, 2);
console.log("成功: 内蔵・Torabo用の表示指示を選び、データ不良時は内蔵表示に戻ります。");
JS
