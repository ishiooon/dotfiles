import CoreBluetooth
import Foundation

enum BatterySide: String {
    case right
    case left
}

func batterySide(format: Data) -> BatterySide? {
    let fields = Array(format)
    // 符号なし8ビット値、指数0、単位はパーセント、Bluetooth SIGの名前空間を照合する。
    guard fields.count == 7, fields.prefix(5).elementsEqual([0x04, 0, 0xad, 0x27, 1]) else { return nil }
    switch UInt16(fields[5]) | UInt16(fields[6]) << 8 {
    case 0x0106: return .right // Zephyrの主電池は右の親機。
    case 0x0108: return .left  // ZMKの補助電池は左の子機。
    default: return nil
    }
}

struct BatteryLevels {
    private var readings: [BatterySide: [Int]] = [:]

    mutating func record(_ data: Data?, side: BatterySide) {
        guard let data, data.count == 1, let value = data.first, value <= 100 else { return }
        // ZMKは左が未接続でも0を返す。測定値と区別できない場合は表示しない。
        guard side != .left || value > 0 else { return }
        readings[side, default: []].append(Int(value))
    }

    var values: [String: Int] {
        Dictionary(uniqueKeysWithValues: readings.compactMap { side, values in
            // 同じ側として複数の値が届いたときは、どれも選ばない。
            guard values.count == 1, let value = values.first else { return nil }
            return (side.rawValue, value)
        })
    }
}

final class Reader: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private let bas = CBUUID(string: "180F")
    private let level = CBUUID(string: "2A19")
    private let presentation = CBUUID(string: CBUUIDCharacteristicFormatString)
    private var central: CBCentralManager!
    private var target: CBPeripheral?
    private var pendingServices = 0
    private var pendingCharacteristics: Set<ObjectIdentifier> = []
    private var sides: [ObjectIdentifier: BatterySide] = [:]
    private var levels = BatteryLevels()

    // すでに無線で接続した機器の電池サービスに問い合わせる。
    func start() {
        central = CBCentralManager(delegate: self, queue: nil,
                                   options: [CBCentralManagerOptionShowPowerAlertKey: false])
        // 初回の Bluetooth 許可ダイアログや GATT 応答待ちの余裕を見る。
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { self.emit() }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .unknown || central.state == .resetting { return }
        guard central.state == .poweredOn else { emit(); return }
        if #available(macOS 10.15, *) {
            // 未許可のまま読みに行くと Karabiner 経由で Abort することがある。
            switch CBCentralManager.authorization {
            case .denied, .restricted:
                FileHandle.standardError.write(Data("bluetooth authorization denied\n".utf8))
                emit()
                return
            default:
                break
            }
        }
        guard target == nil else { return }
        let candidates = central.retrieveConnectedPeripherals(withServices: [bas])
            .filter { $0.name?.caseInsensitiveCompare("Torabo-tsuki S") == .orderedSame }
        guard candidates.count == 1, let peripheral = candidates.first else { emit(); return }
        target = peripheral
        peripheral.delegate = self
        if peripheral.state == .connected {
            peripheral.discoverServices([bas])
        } else {
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([bas])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        emit()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let services = peripheral.services?.filter { $0.uuid == bas } ?? []
        guard error == nil, !services.isEmpty else { emit(); return }
        // 左子機の代理サービスは、右親機と同じUUIDを持つ独立したサービス。
        pendingServices = services.count
        for service in services {
            peripheral.discoverCharacteristics([level], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        pendingServices -= 1
        if error == nil {
            for characteristic in service.characteristics ?? [] where characteristic.uuid == level {
                pendingCharacteristics.insert(ObjectIdentifier(characteristic))
                peripheral.discoverDescriptors(for: characteristic)
            }
        }
        finishIfReady()
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        let descriptors = characteristic.descriptors?.filter { $0.uuid == presentation } ?? []
        guard error == nil, descriptors.count == 1, let descriptor = descriptors.first else {
            finish(characteristic)
            return
        }
        peripheral.readValue(for: descriptor)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        guard let characteristic = descriptor.characteristic else { return }
        guard error == nil, let format = descriptor.value as? Data, let side = batterySide(format: format) else {
            finish(characteristic)
            return
        }
        sides[ObjectIdentifier(characteristic)] = side
        peripheral.readValue(for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil, let side = sides.removeValue(forKey: ObjectIdentifier(characteristic)) {
            levels.record(characteristic.value, side: side)
        }
        finish(characteristic)
    }

    private func finish(_ characteristic: CBCharacteristic) {
        pendingCharacteristics.remove(ObjectIdentifier(characteristic))
        finishIfReady()
    }

    private func finishIfReady() {
        if pendingServices == 0 && pendingCharacteristics.isEmpty { emit() }
    }

    // 確認できた残量だけをJSONで出力し、値がなければキャッシュに使わせない。
    private func emit() {
        var payload = levels.values as [String: Any]
        guard !payload.isEmpty else { exit(EXIT_FAILURE) }
        payload["updated_at"] = ISO8601DateFormatter().string(from: Date())
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else {
            exit(EXIT_FAILURE)
        }
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
        exit(EXIT_SUCCESS)
    }
}

let reader = Reader()
reader.start()
RunLoop.main.run()
