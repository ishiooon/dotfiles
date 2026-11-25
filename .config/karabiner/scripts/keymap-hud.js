#!/usr/bin/env osascript -l JavaScript

// 常駐 HUD デーモン（JS）。
// Usage:
//   osascript -l JavaScript keymap-hud.js daemon <htmlPath> <jsonPath> <pidPath> <cmdPath>
// cmdPath の表示指示に従い、内蔵・外付け・Torabo-tsuki のキー一覧を表示する。

ObjC.import("Cocoa");
ObjC.import("WebKit");

function unwrap(value) {
  return ObjC.unwrap(value);
}

function readText(path) {
  const value = $.NSString.stringWithContentsOfFileEncodingError(
    path,
    $.NSUTF8StringEncoding,
    null
  );
  if (!value) {
    throw new Error(`failed to read: ${path}`);
  }
  return unwrap(value);
}

function writeText(path, text) {
  $.NSString.stringWithString(String(text)).writeToFileAtomicallyEncodingError(
    path,
    true,
    $.NSUTF8StringEncoding,
    null
  );
}

function buildHtmlDocument(html, jsonText, toraboModel) {
  // JSON の文字列に HTML の終了タグがあっても、スクリプトの外へ出ないようにする。
  const embedded = JSON.stringify(JSON.parse(jsonText)).replace(/</g, "\\u003c");
  const injection = `<script>window.__KEYMAP_LAYERS__ = ${embedded};</script><script>${toraboModel}</script>`;
  if (html.indexOf("</head>") !== -1) {
    return html.replace("</head>", () => `${injection}\n</head>`);
  }
  return `${injection}\n${html}`;
}

function batterySubtitle(path) {
  try {
    const battery = JSON.parse(readText(path));
    const parts = [];
    if (Number.isFinite(battery.right)) parts.push(`右 ${battery.right}%`);
    if (Number.isFinite(battery.left)) parts.push(`左 ${battery.left}%`);
    if (parts.length) return parts.join(" · ");
  } catch (error) {}
  return "";
}

function keymapDisplayScript(command, path, batteryPath) {
  const showJis = 'window.showKeymap("jis")';
  if (command === "show external") {
    try {
      // 形状や凡例は内蔵JISと共有し、外付けのレイヤー定義を読み直す。
      const layers = JSON.parse(readText(path.replace(/[^/]+$/, "keymap-layers-external.json")));
      if (Array.isArray(layers) && layers.length) return `window.showKeymap("external", ${JSON.stringify(layers)})`;
    } catch (error) {}
    return showJis;
  }
  if (command !== "show torabo") return showJis;
  try {
    // 表示のたびにToraboの表示用JSONと、保存された電池残量を読み込む。
    const definition = JSON.stringify(JSON.parse(readText(path)));
    const subtitle = (batteryPath && batterySubtitle(batteryPath)) || "電池は次回の表示で更新されます";
    return `try {
      window.__TORABO_KEYMAP__ = buildToraboKeymap(JSON.parse(${JSON.stringify(definition)}));
      window.__TORABO_BATTERY_SUBTITLE__ = ${JSON.stringify(subtitle)};
      window.showKeymap("torabo");
    } catch (error) { ${showJis}; }`;
  } catch (error) {
    return showJis;
  }
}

function run(argv) {
  if (argv[0] !== "daemon") {
    throw new Error("usage: keymap-hud.js daemon <html> <json> <pid> <cmd>");
  }
  const htmlPath = argv[1];
  const jsonPath = argv[2];
  const pidPath = argv[3];
  const cmdPath = argv[4];

  const html = readText(htmlPath);
  const jsonText = readText(jsonPath);
  const configDir = jsonPath.slice(0, jsonPath.lastIndexOf("/") + 1);
  const modelPath = htmlPath.replace(/[^/]+$/, "torabo-keymap-model.js");
  let toraboModel = "";
  try { toraboModel = readText(modelPath); } catch (error) {}
  const documentHtml = buildHtmlDocument(html, jsonText, toraboModel);
  writeText(pidPath, `${$.NSProcessInfo.processInfo.processIdentifier}\n`);
  writeText(cmdPath, "idle\n");

  const app = $.NSApplication.sharedApplication;
  app.setActivationPolicy($.NSApplicationActivationPolicyAccessory);

  // JISでは最大6枚を2列3段に並べ、Toraboではレイヤー数に応じて寸法を調整する。
  const width = 1280;
  const height = 780;
  const panel = $.NSPanel.alloc.initWithContentRectStyleMaskBackingDefer(
    $.NSMakeRect(0, 0, width, height),
    $.NSWindowStyleMaskBorderless | $.NSWindowStyleMaskNonactivatingPanel,
    $.NSBackingStoreBuffered,
    false
  );
  panel.setLevel($.NSFloatingWindowLevel);
  panel.setAlphaValue(0);
  panel.setOpaque(false);
  panel.setBackgroundColor($.NSColor.clearColor);
  panel.setHasShadow(true);
  panel.setIgnoresMouseEvents(true);
  panel.setCollectionBehavior(
    $.NSWindowCollectionBehaviorCanJoinAllSpaces |
      $.NSWindowCollectionBehaviorStationary |
      $.NSWindowCollectionBehaviorFullScreenAuxiliary
  );

  const config = $.WKWebViewConfiguration.alloc.init;
  const webView = $.WKWebView.alloc.initWithFrameConfiguration(
    $.NSMakeRect(0, 0, width, height),
    config
  );
  // WKWebView の白背景を消し、HTML の透明をそのまま出す。
  webView.setValueForKey(false, "drawsBackground");
  webView.setOpaque(false);
  webView.loadHTMLStringBaseURL(documentHtml, $.NSURL.URLWithString("about:blank"));
  panel.setContentView(webView);
  panel.center;
  panel.orderOut(null);

  let lastCmd = "idle";

  function applyCommand(raw) {
    const cmd = String(raw || "").trim();
    if (!cmd || cmd === lastCmd) {
      return;
    }
    lastCmd = cmd;
    if (["show", "show jis", "show external", "show torabo"].includes(cmd)) {
      // 表示内容を切り替えてからパネルを開く。電池は同ディレクトリのキャッシュを読む。
      const batteryPath = cmdPath.replace(/[^/]+$/, "torabo-battery.json");
      webView.evaluateJavaScriptCompletionHandler(
        keymapDisplayScript(cmd, configDir + "torabo-tsuki-s.json", batteryPath),
        function () {
          // 読み込み中にキーが離された場合は、すでに非表示になったパネルを開き直さない。
          if (lastCmd === cmd) {
            panel.setAlphaValue(1);
            panel.orderFrontRegardless;
          }
        }
      );
    } else if (cmd === "hide") {
      panel.setAlphaValue(0);
      panel.orderOut(null);
      writeText(cmdPath, "idle\n");
      lastCmd = "idle";
    } else if (cmd === "quit") {
      panel.orderOut(null);
      app.terminate(null);
    }
  }

  // コマンドファイルを定期的に確認し、表示や終了の指示を反映する。
  function tick() {
    try {
      const raw = readText(cmdPath);
      applyCommand(raw);
    } catch (error) {
      console.log(`キー一覧の指示を処理できませんでした。${error.message}`);
    }
    $.NSTimer.scheduledTimerWithTimeIntervalRepeatsBlock(0.03, false, function () {
      tick();
    });
  }

  try {
    tick();
  } catch (error) {
    // タイマーが使えなくても、初回 show 待ちで runloop は回す。
  }

  app.run();
}
