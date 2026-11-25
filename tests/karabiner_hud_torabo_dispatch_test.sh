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
console.log("成功: 内蔵・Torabo用の表示指示を選び、データ不良時は内蔵表示に戻ります。");
JS
