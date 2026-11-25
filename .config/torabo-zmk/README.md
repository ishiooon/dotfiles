# Torabo-tsuki (S) のZMK設定

右手側にトラックボールがある通常版Torabo-tsuki (S) 用です。[製作者のZMK版](https://github.com/sekigon-gonnoc/zmk-keyboard-torabo-tsuki)を使い、右を親機、左を子機としてビルドします。

- [キー割り当て](config/torabo_tsuki.keymap) に、ドラッグスクロールとメディア操作を含む10レイヤーを定義します。Fを保持してBを押すとF24が送られ、Macでキー一覧が開きます。
- [トラックボールの設定](config/torabo-pointing.dtsi) ではボールを動かしたときにレイヤー1へ入ります。[本体の設定](config/torabo_tsuki.conf) でカーソル分解能600、マウスレイヤーが有効な時間664ミリ秒、無操作から15分でのディープスリープを指定します。
- [記憶領域の設定](config/ble_micro_pro.overlay) はZMKの保存先を専用領域に移し、BMP/Vialの保存先と重なるのを防ぎます。Vialに戻すためのファームウェアと左右のバックアップは、ユーザー限定の `~/.local/share/torabo-firmware-backup/` に保管しました。
- Macのキー一覧は [Toraboの表示用データ](../karabiner/torabo-tsuki-s.json) を読みます。キーを変えるときはZMKのキー割り当てと表示データの両方に反映してください。ZMK StudioはUSB接続時に使えます。Studioで本体上だけを編集した変更はdotfilesに手動で反映してください。

## 設定を編集してビルドする

1. GitHubで `config/torabo_tsuki.keymap` を開き、変更するレイヤーのキーを書き換えます。カーソル速度や休止時間は `config/torabo_tsuki.conf` で変更できます。Macの一覧にも反映する場合は、同じ位置を [表示用のJSON](../karabiner/torabo-tsuki-s.json) に記録します。
2. mainに変更が入るとビルドが始まります。手動でビルドするときは [GitHub ActionsのToraboビルド](https://github.com/ishiooon/dotfiles/actions/workflows/torabo-zmk.yml) で「Run workflow」を選びます。
3. 成功した実行結果の「Artifacts」から `torabo-tsuki-s-firmware` をダウンロードします。ZIPには右親機・左子機・設定消去用の `.uf2` と、使った依存関係の一覧が入っています。

ブラウザからの編集・ビルドはMac、Windows、Linuxで同じ手順です。MacのF長押し＋Bによるキー一覧にはKarabiner-Elementsが必要です。Torabo本体では `F` 押し込み中の `N` が英数（ABC）、`M` がかな（あいう）です。Macの内蔵JISでは、物理 `e` を保持して `;` で英数、`:` でかなに切り替えます。

### 手元でビルドする

MacはDocker Desktop、LinuxはDocker Engine、WindowsはDocker DesktopのWSL 2連携を有効にしたLinuxシェルを使います。Arm64とx86-64のDockerに対応しています。dotfilesのルートで実行します。

```sh
bash .config/torabo-zmk/build-local.sh
```

作業フォルダは実行時に表示されます。右親機・左子機・設定消去用の `.uf2` はその中の `firmware/` に生成され、使ったソースの版は `resolved-west.yml` に残ります。以前の作業フォルダを引数にすると、取り込んだソースを再利用できます。

ZMK Studioで保存した割り当ては再書き込み後も残ります。リポジトリのキー割り当てを使うときは、Studioで「Restore Stock Settings」を選びます。[ZMK Studioの公式手順](https://zmk.dev/docs/features/studio)

## ファームウェアの切り替え

左右を1台ずつUSB接続し、書き込みモードの `BLEMICROPRO` に、それぞれの役割の `.uf2` を転送します。この実機では転送後も書き込みドライブが残りました。転送が終わってからUSBを抜いて電源を切り、キーを押さずに挿し直すと、左右とも `Torabo-tsuki S` として起動しました。右だけがUSBキーボードとして入力を送ります。

左右の電源を入れ、最初は右をUSBで給電したままMacのBluetooth設定から `Torabo-tsuki S` に接続します。旧 `(BMP)torabo-tsuki` の登録と競合する場合は、Macでその機器の登録を解除してから再検索します。[ZMKのBluetooth接続の切り分け](https://zmk.dev/docs/troubleshooting/connection-issues)

接続が進まないときは、Macから機器を削除します。右をUSB接続したまま `B` を長押しして `F` でプロファイル0を選び、続けて `B` を長押しして `D` でそのプロファイルを消去してから、Macと再ペアリングします。

### Bluetoothが繋がらないとき（settings reset）

プロファイルを消しても接続できない場合は、左右のZMK設定を消去してから通常ファームを書き直します。この構成で作った `settings-reset-ble-micro-pro.uf2` は、ZMK専用の保存領域にあるペアリングやStudioの保存内容を消去します。

1. MacのBluetoothから `Torabo-tsuki S` を削除する。
2. 右をUSB接続し、ブートローダ（`BLEMICROPRO`）を起動して `settings-reset-ble-micro-pro.uf2` を入れる。
3. **USBを抜き → 電源オン → もう一度USBを挿す**（書き込みだけではリセットが完了しない）。
4. 左も同じ手順で settings reset する。
5. 右に `torabo-tsuki-s-right-central.uf2`、左に `torabo-tsuki-s-left-peripheral.uf2` を書き込む。
6. 左右の電源を入れ、右をUSB給電したままBluetoothで再ペアする。

ブートローダの出し方:

- **右親機:** `B` を長押ししながら `P` を押すと、右親機がブートローダ（`BLEMICROPRO`）に入ります。通常の `P` 単体は文字入力のままです。
- **予備:** USB接続中にシリアルを1200bpsで開いて閉じる。`ls /dev/tty.usb*` でポートを確認し、`screen /dev/tty.usbmodem… 1200` のあと `Ctrl+a` → `k` → `y`。
- **settings reset 直後など、通常起動しないとき:** マイコンの BOOT と GND をショートしたままUSB接続します。

Bluetooth接続ではZMK版がキーボードとマウスの両方として認識されます。[Karabinerの設定](../karabiner/karabiner.json)ではToraboを明示的に処理対象にし、F24での一覧表示と、F1〜F12を標準ファンクションキーとして送る処理を行います。ToraboのFを長押ししながらBを押すと、Bを押している間にキー一覧が表示されます。Bluetooth接続時は裏で左右の電池残量を読み、**次回**の一覧表示の見出しに出します（例: `右 80% · 左 70%`）。初回は「このMacのBluetoothを許可」などのダイアログが出ることがあり、システム設定 → プライバシーとセキュリティ → Bluetooth で `torabo-battery` や Karabiner-Elements がオンになっている必要があります。USBのみの接続では残量は取れません。

## Vialに戻すとき

保持している `torabo-tsuki-vial-1.3.3.uf2` は、この実機と同じ版の純正ファームウェアです。左右を1台ずつ書き込みモードにしてこのファイルを転送し、起動後に同じ側のバックアップと `CONFIG.BIN`、`EEPROM.BIN` を照合します。EEPROMを再転送すると初期値の保存内容も現在値に更新されるため、再転送が必要か判断する前に `DEFAULT.BIN` も照合します。Bluetoothの再ペアリングが必要な場合は、Macに表示される機器を確認して接続します。[EEPROMの保存処理](https://github.com/sekigon-gonnoc/vial-qmk/blob/45aa1bf436/tmk_core/protocol/bmp/bmp_file.c#L31-L47)

## 実機で確認した操作

2026年11月24日、左右がZMKで起動し、USBを外した状態で左右の文字入力、ボールによるカーソル移動、Fを保持してBを押したときのToraboのキー一覧を確認しました。クリック、ドラッグスクロール、Consumer HIDに置き換えた電源・スリープキーは、個別の実機確認が残っています。

Toraboの操作直後にMacをスリープさせた試験では、30秒間画面が勝手に点きませんでした。ログにはバックグラウンド復帰がありましたが、前回のToraboのBluetooth通信による画面点灯は記録されませんでした。ディープスリープの15分はToraboの無操作時間で進みます。詳しい再現条件は [Macの復帰の調査記録](../karabiner/torabo-tsuki-s.md) を参照してください。
