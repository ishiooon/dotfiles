#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--env=localdev" ]]; then
  echo "--env=localdev を指定してください。" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 実際のキー一覧と同じJavaScriptを隔離した環境で動かし、キー入力や画面操作を行わずに表示内容を検証する。
node - "$ROOT_DIR/.config/karabiner" <<'JS'
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

class Element {
  constructor() {
    this.children = [];
    this.classes = new Set();
    this.dataset = {};
    this.style = { setProperty: (name, value) => { this.style[name] = value; } };
    this.classList = {
      add: (name) => this.classes.add(name),
      remove: (name) => this.classes.delete(name),
      toggle: (name, enabled) => enabled ? this.classes.add(name) : this.classes.delete(name),
    };
  }

  appendChild(element) { this.children.push(element); }
  replaceChildren() { this.children = []; }
}

function openKeymap(definition) {
  const config = process.argv[2];
  const html = fs.readFileSync(path.join(config, 'scripts/keymap-hud.html'), 'utf8');
  const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];
  const layers = new Element();
  const heading = new Element();
  const sub = new Element();
  const document = {
    body: new Element(),
    createElement: () => new Element(),
    getElementById: () => layers,
    querySelector: (selector) => selector === '#keymap-sub' ? sub : heading,
  };
  const window = {
    __KEYMAP_LAYERS__: JSON.parse(fs.readFileSync(path.join(config, 'keymap-layers.json'), 'utf8')),
    __TORABO_KEYMAP__: definition,
  };
  vm.runInNewContext(script, { window, document }, { timeout: 5000 });
  return { window, layers, heading, sub, body: document.body };
}

function hasClass(element, name) {
  return element.classes.has(name) || element.className?.split(/\s+/).includes(name);
}

function findElement(root, matches) {
  if (matches(root)) return root;
  for (const child of root.children) {
    const match = findElement(child, matches);
    if (match) return match;
  }
}

function keyAt(board, position) {
  const keyboard = findElement(board, (element) => hasClass(element, 'macbook-keyboard'));
  assert.ok(keyboard, '内蔵JISはMacBookの物理配置で描画する');
  const key = findElement(keyboard, (element) => element.dataset.key === position);
  assert.ok(key && hasClass(key, 'key'), `物理キー ${position} の輪郭を表示する`);
  return key;
}

function labelOf(element) {
  return [element.textContent, ...element.children.map(labelOf)].join('').trim();
}

function verifyBuiltInLayers(layers) {
  const holders = [['e', 'F'], ['w', 'D'], ['d', 'V'], ['s', 'C'], ['a', 'X']];
  for (const [index, [physical, moved]] of holders.entries()) {
    const board = layers.children[index + 1];
    assert.match(board.children[0].children[0].textContent, new RegExp(`${moved} 押し込み中`));
    const holder = keyAt(board, physical);
    assert.ok(hasClass(holder, 'holder'), `物理キー ${physical} を押し込み位置として強調する`);
    assert.equal(labelOf(holder), moved, '押し込み位置には移動後の文字を表示する');
  }
  const [, movement, numbers] = layers.children;
  assert.equal(labelOf(keyAt(movement, '3')), '⌫');
  assert.equal(labelOf(keyAt(numbers, ';')), '1');
  assert.equal(labelOf(keyAt(numbers, '4')), '', '数字レイヤーに割り当てのないキーは無地にする');
  for (const direction of ['left', 'up', 'down', 'right']) {
    assert.equal(labelOf(keyAt(movement, `${direction}_arrow`)), '', '未割り当ての矢印は輪郭だけ表示する');
  }
}

function verifyMacBookGeometry(board) {
  // Fキー列と各段の右端を照合し、矢印の下段が修飾キーと同じ底辺に並ぶことを確かめる。
  const edge = (key, origin, size) =>
    parseFloat(keyAt(board, key).style[origin]) + parseFloat(keyAt(board, key).style[size]);
  for (let number = 1; number <= 12; number++) {
    assert.equal(labelOf(keyAt(board, `f${number}`)), `F${number}`);
  }
  for (const key of ['touch_id', 'delete', 'return', 'shift_r', 'right_arrow']) {
    assert.ok(Math.abs(edge(key, '--key-left', '--key-width') - 100) < 0.0001, key);
  }
  const bottom = (key) => edge(key, '--key-top', '--key-height');
  for (const key of ['left_arrow', 'down_arrow', 'right_arrow', 'fn']) {
    assert.ok(Math.abs(bottom(key) - 100) < 0.0001, key);
  }
  assert.ok(bottom('up_arrow') < bottom('down_arrow'));
  assert.ok(parseFloat(keyAt(board, 'fn').style['--key-left']) > parseFloat(keyAt(board, 'command_r').style['--key-left']));
}

const options = {
  name: 'Torabo-tsuki (S)',
  summary: 'キーボードに保存した割り当て',
  keys: [{ id: 'left', x: -1, y: 1 }, { id: 'right', x: 5.25, y: 0 }],
  layers: [{ name: '通常', bindings: { left: 'F', right: 'B' } }, { name: '数字', bindings: { left: '1', right: '0' } }],
};
const { window, layers, heading, sub, body } = openKeymap(options);
assert.equal(layers.children.length, 6, '最初はJISの base/f/d/v/c/x レイヤーを表示する');
assert.ok(body.classes.has('jis-keymap-compact'), 'JISの6層をウィンドウに収める寸法を使う');
assert.match(heading.textContent, /MacBook Pro 14インチ/);
verifyMacBookGeometry(layers.children[0]);
verifyBuiltInLayers(layers);
window.__TORABO_BATTERY_SUBTITLE__ = '右 80% · 左 70%';
window.showKeymap('torabo');
assert.equal(heading.textContent, 'Torabo-tsuki (S)');
assert.match(sub.textContent, /右 80%/);
assert.equal(layers.children.length, 2, '設定にあるレイヤーをすべて表示する');
assert.ok(!body.classes.has('jis-keymap-compact'), 'ToraboはJIS専用の寸法を使わない');
const [firstBoard, secondBoard] = layers.children;
assert.equal(firstBoard.children[0].children[0].textContent, '通常');
assert.equal(secondBoard.children[0].children[0].textContent, '数字');
const [left, right] = firstBoard.children[1].children;
assert.equal(left.textContent, 'F');
assert.equal(right.textContent, 'B');
assert.equal(left.style['--key-x'], '0');
assert.equal(right.style['--key-x'], '6.25');
assert.equal(right.style['--key-y'], '0');
assert.equal(secondBoard.children[1].children[0].textContent, '1');

window.showKeymap('jis');
assert.match(heading.textContent, /JIS/);
assert.equal(layers.children.length, 6, '切断後はJISの base/f/d/v/c/x レイヤーへ戻る');
assert.ok(body.classes.has('jis-keymap-compact'), 'JISに戻ると6層用の寸法に戻る');

// 外付けのFレイヤーと、内蔵の物理Eで開く論理Fレイヤーを区別する。
const external = JSON.parse(fs.readFileSync(path.join(process.argv[2], 'keymap-layers-external.json'), 'utf8'));
assert.equal(window.showKeymap('external', external), 'external');
assert.match(heading.textContent, /外付け/);
assert.equal(layers.children.length, 6);
assert.match(layers.children[1].children[0].children[0].textContent, /f 押し込み中/);
assert.equal(window.showKeymap('jis'), 'jis');
verifyBuiltInLayers(layers);

// Returnに割り当てがなくても、二段をまたぐJIS固有のキー形状を維持する。
const withoutReturn = openKeymap(options);
delete withoutReturn.window.__KEYMAP_LAYERS__.layers[1].bindings.return;
withoutReturn.window.showKeymap('jis');
const blankReturn = keyAt(withoutReturn.layers.children[1], 'return');
assert.ok(hasClass(blankReturn, 'jis-return'));
assert.equal(labelOf(blankReturn), '');

const manyLayers = openKeymap({ ...options, layers: Array.from({ length: 16 }, (_, index) => ({
  name: `レイヤー${index}`, bindings: { left: '<設定>', right: 'F12' },
})) });
manyLayers.window.showKeymap('torabo');
assert.equal(manyLayers.layers.children.length, 16);
assert.equal(manyLayers.layers.style['--torabo-columns'], '4');
assert.equal(manyLayers.layers.style['--torabo-rows'], '4');
assert.equal(manyLayers.layers.children[15].children[1].children[0].textContent, '<設定>');

for (const definition of [undefined, { ...options, keys: [] }, { ...options, layers: [] }, { ...options, layers: [null] }]) {
  const hud = openKeymap(definition);
  hud.window.showKeymap('torabo');
  assert.match(hud.heading.textContent, /JIS/);
  assert.equal(hud.layers.children.length, 6, 'Toraboの表示データがなければJISを維持する');
}
console.log('成功: 接続状態に応じてTorabo-tsuki (S)とJISの表示が切り替わります。');
JS
