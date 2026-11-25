# Torabo-tsuki (S) のキーマップ

ZMK版のキー割り当ては [torabo_tsuki.keymap](../torabo-zmk/config/torabo_tsuki.keymap) で管理します。MacでToraboのキー一覧を開くたびに、表示用の [torabo-tsuki-s.json](torabo-tsuki-s.json) を読み込みます。キーを変更するときは [ZMKの手順](../torabo-zmk/README.md) に沿って、ファームウェアのキーマップとMacの表示用データの両方を更新します。変更を依頼するときは「Toraboの数字レイヤーで、右手小指側のキーを0に」など、レイヤーと物理キーと希望する動作を伝えてください。

Toraboでは `f` を長押ししてから `b` を押すと、移動レイヤーのB位置が表示用の `F24` を送り、Karabinerがキー一覧を開きます。同じ `f` 保持中の `n` が英数（ABC）、`m` がかな（あいう）です。ZMKでは `LANG2` と `LANG1` を使います。Macの内蔵JISでは、物理 `e` を保持して `f` で内蔵のキー一覧、`;` で英数、`:` でかなに切り替えます。

## BMP/Vial版の設定を編集する

[torabo-vial-keymap.json](torabo-vial-keymap.json) は、ZMKへの移行前にBMP/Vial版からUSBで取得した8レイヤーのキー割り当てです。この節の書き込み手順はBMP/Vial版のみに適用します。ZMKの表示用JSONは編集ツールが接続前に拒否します。

`keys` にある `id` は、0から始まる「行,列」です。対象レイヤーの `matrix[行][列]` にQMKのキーコードを16進で記載します。 `0x0000` は無効、`0x0001` は下のレイヤーの割り当てを使います。Vialが保持していたレイアウト選択値は `source.layout_options` に記録しています。キー一覧の物理配置はSサイズです。

USB接続時に [編集ツール](scripts/torabo-keymap-device.swift) が、ファイル上の1キーを本体に反映できます。実機の現在値が指定した変更前のキーコードと一致することを確かめてから書き込み、直後に読み直します。マクロとコンボはこの編集ツールの範囲外です。トラックボールの主要設定は [torabo-trackball.json](torabo-trackball.json) に別途保存しています。

```sh
swiftc -module-cache-path /private/tmp/torabo-swift-cache \
  ~/.config/karabiner/scripts/torabo-keymap-device.swift \
  -o /private/tmp/torabo-keymap-device
/private/tmp/torabo-keymap-device read
# F を保持したときの B の位置を、ファイルに設定した値で更新する場合。
/private/tmp/torabo-keymap-device apply-key ~/.config/karabiner/torabo-vial-keymap.json 2 2 5 0x0001
```

物理配置は[製作者のVial定義](https://github.com/sekigon-gonnoc/vial-qmk/blob/dev/ble-micro-pro/keyboards/sekigon/torabo_tsuki/keymaps/vial/vial.json)を基にしました。読み取り・編集には[Vialの公式プロトコル](https://github.com/vial-kb/vial-gui/blob/main/src/main/python/protocol/keyboard_comm.py)を使います。

2026年11月24日の初回反映では、本体のL2・行2・列5だけを `0x0001` から `0x0073` へ変更しました。実機の全560セルを読み直し、編集元と一致し、ほかのセルに変更がないことを確認しました。接続判定・レイヤー表示・編集入力のテストと、Mac上でのキー一覧ウィンドウの開閉確認も行いました。物理キーを押しての確認は未実施です。

元に戻すときは、編集元のL2・行2・列5を `0x0001` にし、上記の反映コマンドの最後に現在の値 `0x0073` を指定します。

## トラックボールが動かない場合

オートマウスレイヤーは、ボールを動かしたときにマウスボタンなどのレイヤーへ移る機能です。別の「Encoder → Layer」で基本レイヤーを選ぶと、ボールの動きがエンコーダ入力に置き換わり、カーソルの移動量がゼロになります。

2026年11月24日、実機の「Encoder → Layer」でレイヤー0だけが選ばれていたため、この選択を解除して保存しました。前後の読み取りでこの1項目だけが変わり、オートマウスレイヤーは有効、移動先はレイヤー1のままです。戻す場合は設定画面で Encoder → Layer の0を再び選択して Save Custom を実行します。[作者の設定ガイド](https://github.com/sekigon-gonnoc/torabo-tsuki/blob/main/build-guide.md)・[カーソルの処理](https://github.com/sekigon-gonnoc/vial-qmk/blob/dev/ble-micro-pro/keyboards/sekigon/torabo_tsuki/keymaps/vial/keymap.c)

## Macがスリープ直後に復帰する場合

普段の接続はBluetoothのみです。11月23日16時38分と16時39分の手動スリープでは、約1秒後に `USB-C_plug` を含むバックグラウンド復帰と、`Bluetooth LE HID Activity` を伴う画面の復帰が同じ秒に記録されました。

11月24日は設定作業用のUSBケーブルを外した状態でも再現しました。02時19分28秒に手動スリープし、31秒に画面が点灯しました。02時18分と19分の2回とも、復帰時の `AP wakeup by LE Data` が示す機器識別子はToraboに一致しました。Bluetoothの通信内容はログから確定できていません。

Toraboの左右の電源だけを切った比較では、画面は勝手に点かなかったとの報告がありました。暫定対処は、Macをスリープさせる前にToraboの左右の電源を切り、Macを起こしてからToraboを再びオンにする方法です。[Appleの切り分け手順](https://support.apple.com/ja-jp/guide/mac-help/mchlp2995/mac)・[Toraboの電源操作](https://github.com/sekigon-gonnoc/torabo-tsuki/blob/main/build-guide.md)

macOS 27.0の標準設定では、このキーボードに限って復帰を抑止する項目を確認できませんでした。Bluetoothのトラックボールで同様の現象が起き、スリープ中にBluetoothを一時停止して回避した事例があります。元のBluesnoozeには、macOS 26で復帰後にBluetoothが戻らなかった報告があります。[トラックボールの事例](https://eupholab.net/entry/2023/06/05/110947)・[Bluesnoozeの報告](https://github.com/odlp/bluesnooze/issues/52)

BlueNap 0.1.2と同じ方法でToraboだけに切断を要求しました。要求は成功を返しましたが、2秒間の確認でBluetooth接続は切れず、Bluetooth入力機器としての登録も残っていたため、この方法は採用しませんでした。[BlueNapの切断処理](https://github.com/root913/bluenap/blob/v0.1.2/BlueNap/BluetoothServices.swift)

実機のファームウェアには、Macと接続する側を手動で深いスリープに入れる `ENT_SLP` があります。現在のキーマップでは未割り当てです。左右同時の休止と、任意のキーでの復帰は実機で未確認です。[実機と同じ版のスリープ処理](https://github.com/sekigon-gonnoc/vial-qmk/blob/45aa1bf436/tmk_core/protocol/bmp/state_controller.c#L203-L208)

### ZMKのディープスリープを検討した結果

移行前に実機から読み取ったファームウェアはBMP/Vialの `bmp-vial-1.3.3-0-g45aa1bf436` です。ZMKの `CONFIG_ZMK_SLEEP` と `CONFIG_ZMK_IDLE_SLEEP_TIMEOUT` を使うため、左右両方のファームウェアを切り替え、オートマウスレイヤーやキー割り当てを移植しました。[製作者のZMK版](https://github.com/sekigon-gonnoc/zmk-keyboard-torabo-tsuki)

ZMKのタイマーはキーボードの無操作時間で、Macのスリープ開始とは連動しません。無操作から5分または15分でディープスリープする設定では、Macを寝かせた時点でToraboがまだ接続されている場合、今回のような約3秒後の画面点灯を防げるとは限りません。[ZMKの電源設定](https://zmk.dev/docs/config/power)・[macOSでの報告](https://github.com/zmkfirmware/zmk/issues/1273)

右側にトラックボールがある実機向けの設定で、ZMKのディープスリープは無操作15分です。編集とビルドは [ZMK設定](../torabo-zmk/README.md) を参照してください。ファームウェアを切り替える前のVial設定は左右別に退避しています。
