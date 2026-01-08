//
//  ViewController.swift
//  BLE_Test3
//
//  Created by Terry Burdett on 12/13/25.
//

import UIKit
import CoreBluetooth
import zlib

var selectedDeviceID: String?
var connectedPeripheral: CBPeripheral?

var textRxChar: CBCharacteristic?   // iOS → ESP32 (text)

class AvailableDevices_ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

   // @IBAction func rescanForBLEDevices(_ sender: Any) {
      //  reScan()
   // }
    var centralManager: CBCentralManager!
    var peripherals: [CBPeripheral] = []
    var peripheralNames: [UUID: String] = [:]

    var receivedPackets: [Int: Data] = [:]
    var expectedPacketCount: Int?


    // MARK: - Connected peripheral
    //var connectedPeripheral: CBPeripheral?
    
    //var textRxChar: CBCharacteristic?   // iOS → ESP32 (text)
    var dataRxChar: CBCharacteristic?   // iOS → ESP32 (binary)
    var textTxChar: CBCharacteristic?   // ESP32 → iOS (text)
    var dataTxChar: CBCharacteristic?   // ESP32 → iOS (binary)

    var idChar: CBCharacteristic?

    
    
    var minuteTimer: Timer?
    let notificationCenter = NotificationCenter.default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationCenter.addObserver(self, selector: #selector(setColor), name: Notification.Name(rawValue: "setColor"), object: nil)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = true
        notificationCenter.addObserver(self, selector: #selector(upDateESPArray), name: Notification.Name(rawValue: "upDateESPArray"), object: nil)
        ledsInfo_Array.removeAll()
        receivedPackets.removeAll()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ledsInfo_Array.removeAll()
        receivedPackets.removeAll()
        if let id = selectedDeviceID,
              let row = BLEDeviceStore.shared.devices.firstIndex(
                  where: { $0.id == id }
              ) {
               tableView.selectRow(
                   at: IndexPath(row: row, section: 0),
                   animated: false,
                   scrollPosition: .none
               )
           }
    }

    func crc32(_ data: Data) -> UInt32 {
        return data.withUnsafeBytes {
            UInt32(zlib.crc32(0, $0.bindMemory(to: UInt8.self).baseAddress, uInt(data.count)))
        }
    }
    
    func reScan() {
        print("rescan start")
        guard centralManager.state == .poweredOn else { return }

        centralManager.stopScan()

        DispatchQueue.main.async {
            self.peripherals.removeAll()
            self.peripheralNames.removeAll()
            self.tableView.reloadData()
        }

        // Give CoreBluetooth time to reset the scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.centralManager.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }
        print("rescan end")
    }
    
    
    @objc func setColor() {
        sendText(bleSendText)
    }
    
    func decodeLedsInfo(from data: Data) -> [LedsInfo] {
        var result: [LedsInfo] = []
        let structSize = 18
        var offset = 0

        while offset + structSize <= data.count {

            var interval: UInt32 = 0
            var candleBlue: UInt32 = 0
            var candleRed: Int32 = 0
            var candleGreen: Int32 = 0

            // SAFE memcpy-style copies
            withUnsafeMutableBytes(of: &interval) {
                data.copyBytes(to: $0, from: offset + 0 ..< offset + 4)
            }

            withUnsafeMutableBytes(of: &candleBlue) {
                data.copyBytes(to: $0, from: offset + 4 ..< offset + 8)
            }

            withUnsafeMutableBytes(of: &candleRed) {
                data.copyBytes(to: $0, from: offset + 10 ..< offset + 14)
            }

            withUnsafeMutableBytes(of: &candleGreen) {
                data.copyBytes(to: $0, from: offset + 14 ..< offset + 18)
            }

            let baseBrightness = data[offset + 8]
            let house          = data[offset + 9]

           let array = LedsInfo(
                interval: UInt32(littleEndian: interval),
                candleBlue: UInt32(littleEndian: candleBlue),
                baseBrightness: baseBrightness,
                house: house,
                candleRed: Int32(littleEndian: candleRed),
                candleGreen: Int32(littleEndian: candleGreen)
            )
            ledsInfo_Array.append(array)
            print("*** \(ledsInfo_Array.count) ***")
            print("array = \(array)")
            
            
            result.append(
                LedsInfo(
                    interval: UInt32(littleEndian: interval),
                    candleBlue: UInt32(littleEndian: candleBlue),
                    baseBrightness: baseBrightness,
                    house: house,
                    candleRed: Int32(littleEndian: candleRed),
                    candleGreen: Int32(littleEndian: candleGreen)
                )
            )
            

            offset += structSize
        }

        return result
    }

    func assembleAndDecodeLedsInfo() {

        guard let total = expectedPacketCount else { return }

        var fullData = Data()

        for p in 0..<total {
            guard let packet = receivedPackets[p] else {
                print("Missing packet \(p)")
                return
            }
            fullData.append(packet)
        }

        let ledsInfoArray = decodeLedsInfo(from: fullData)
        print("Decoded \(ledsInfoArray.count) LedsInfo structs") // ✅ 50
        
        
        let vc = storyboard?.instantiateViewController(
            withIdentifier: "SelectLED"
        )
        navigationController?.pushViewController(vc!, animated: true)
    }

    func makeLedData() {
        ledsInfo_Array.removeAll()
        for i in 0..<50 {
            ledsInfo_Array.append(
                LedsInfo(
                    interval: UInt32(100 + i),
                    candleBlue: 0,
                    baseBrightness: UInt8(100),
                    house: UInt8(i % 4),
                    candleRed: Int32.random(in: 0...10000),
                    candleGreen: Int32.random(in: 0...10000)
                )
            )
        }
    }

    @objc func upDateESPArray() {
        sendText("send data to esp32")   // tells ESP32 to startBinaryReception()
        if ledsInfo_Array.isEmpty {
            makeLedData()
        }
        let payload = ledsInfo_Array.toData()
        
       //single test
       //sendText("sending single data to esp32")
        //let payload = toSingle_Data(info: ledsInfo_Array[5])
        // single end
        let crc = crc32(payload)

        var header = Data()
        header.append(contentsOf: [0xA5, 0xA5])           // magic
        header.append(1)                                  // version
        header.append(UInt32(payload.count).littleEndianData)
        header.append(crc.littleEndianData)

        // Send header
        guard let peripheral = connectedPeripheral,
              let dataRxChar = dataRxChar else { return }
        peripheral.writeValue(header, for: dataRxChar, type: .withResponse)

        // Send payload in chunks
        sendChunkedData(payload)
    }
    
    func sendChunkedData(_ data: Data) {
        print("ledsInfo_Array.count = \(ledsInfo_Array.count)")
        guard let peripheral = connectedPeripheral,
              let dataRxChar = dataRxChar else { return }
print(ledsInfo_Array)
        let chunkSize = 180
        var offset = 0
        print(data.count)
        while offset < data.count {
            let end = min(offset + chunkSize, data.count)
            let chunk = data.subdata(in: offset..<end)

            peripheral.writeValue(chunk,
                                  for: dataRxChar,
                                  type: .withResponse)
            
            offset = end
            print(offset)
        }
        sendText("array data sent")
    }

    func toSingle_Data(info: LedsInfo) -> Data {
 
            var data = Data()
            data.reserveCapacity(18)

                var interval   = info.interval.littleEndian
                var candleBlue = info.candleBlue.littleEndian
                var candleRed    = info.candleRed.littleEndian
                var candleGreen    = info.candleGreen.littleEndian

                Swift.withUnsafeBytes(of: &interval) {
                    data.append(contentsOf: $0)
                }

                Swift.withUnsafeBytes(of: &candleBlue) {
                    data.append(contentsOf: $0)
                }

                data.append(info.baseBrightness)
                data.append(info.house)

                Swift.withUnsafeBytes(of: &candleRed) {
                    data.append(contentsOf: $0)
                }

                Swift.withUnsafeBytes(of: &candleGreen) {
                    data.append(contentsOf: $0)
                }
         //   }

            return data
      //  }
    }

}

// MARK: - CBCentralManagerDelegate
extension AvailableDevices_ViewController: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            peripherals.removeAll()
            
            central.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false])

        }
        
        
        DispatchQueue.main.async {
                switch central.state {
                case .poweredOn:
                    self.navigationItem.title = "BLE Devices Available"

                case .poweredOff:
                    self.navigationItem.title = "Bluetooth Off"

                default:
                    self.navigationItem.title = "Bluetooth Unavailable"
                }
            }
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {

        
        guard !peripherals.contains(where: { $0.identifier == peripheral.identifier }) else {//skip if duplicate
            print("skip peripheral \(peripheral.identifier)")
            return
        }
 
        peripherals.append(peripheral)
        
        guard let data = advertisementData[
            CBAdvertisementDataManufacturerDataKey
        ] as? Data else { return }
        // Skip company ID (2 bytes)
        
        let nameData = data.dropFirst(2)
        let deviceName = String(decoding: nameData, as: UTF8.self)
        print("Device ID:", deviceName)
        
        let id = String(decoding: data.dropFirst(2), as: UTF8.self)
        
        let r = peripheral.identifier.uuidString
        print("r = \(r)")
        peripheralNames[peripheral.identifier] = id
        print("peripheralNames[peripheral.identifier] = \(id)")
        
        BLEDeviceStore.shared.upsert(
            peripheral: peripheral,
            id: id
        )

        tableView.reloadData()
    }

    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        
        BLEDeviceStore.shared.setConnectionState(
                peripheral,
                connected: true
            )
            tableView.reloadData()
        
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([SERVICE_UUID])
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        BLEDeviceStore.shared.setConnectionState(
            peripheral,
            connected: false
        )
        tableView.reloadData()
    }

    
}

// MARK: - CBPeripheralDelegate
extension AvailableDevices_ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {

        guard let services = peripheral.services else { return }

        for service in services where service.uuid == SERVICE_UUID {
            peripheral.discoverCharacteristics(
                [
                    TEXT_RX_UUID,   // iOS → ESP32 (text commands)
                    DATA_RX_UUID,   // iOS → ESP32 (binary upload)
                    TEXT_TX_UUID,   // ESP32 → iOS (text notify)
                    DATA_TX_UUID,   // ESP32 → iOS (binary notify)
                    ID_CHAR_UUID    // ESP32 → iOS (device ID)
                ],
                for: service
            )
        }
    }


    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {

        guard let characteristics = service.characteristics else { return }

        for char in characteristics {
            print("Discovered characteristic:", char.uuid)

            switch char.uuid {

            case TEXT_RX_UUID:
                textRxChar = char
                print("Found TEXT_RX")

            case DATA_RX_UUID:
                dataRxChar = char
                print("Found DATA_RX")

            case TEXT_TX_UUID:
                textTxChar = char
                peripheral.setNotifyValue(true, for: char)
                print("Found TEXT_TX")

            case DATA_TX_UUID:
                dataTxChar = char
                peripheral.setNotifyValue(true, for: char)
                print("Found DATA_TX")

            case ID_CHAR_UUID:
                idChar = char
                peripheral.readValue(for: char)
                print("Found ID")

            default:
                break
            }
        }

        // Ready
        if textRxChar != nil,
           dataRxChar != nil,
           textTxChar != nil,
           dataTxChar != nil {

            print("✅ BLE ready")
            sendText("send array to ios")   // tells ESP32 to startBinaryReception()
        }
    }



    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {

        guard let data = characteristic.value else { return }

        // ---------- TEXT ----------
        if characteristic.uuid == TEXT_TX_UUID {
            let text = String(data: data, encoding: .utf8) ?? ""
            print("📩 TEXT:", text)
            return
        }

        // ---------- BINARY ----------
        if characteristic.uuid == DATA_TX_UUID {

            let bytes = [UInt8](data)
            guard bytes.count >= 2 else { return }

            let packetIndex  = Int(bytes[0])
            let totalPackets = Int(bytes[1])

            if expectedPacketCount == nil {
                expectedPacketCount = totalPackets
                receivedPackets.removeAll()
                print("Expecting \(totalPackets) packets")
            }

            let payload = data.subdata(in: 2..<data.count)
            receivedPackets[packetIndex] = payload

            print("📦 Packet \(packetIndex + 1)/\(totalPackets)")

            if receivedPackets.count == totalPackets {
                assembleAndDecodeLedsInfo()
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension AvailableDevices_ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLEDeviceStore.shared.devices.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "BLECell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "BLECell")

        
        let device =
               BLEDeviceStore.shared.devices[indexPath.row]

        cell.backgroundColor = UIColor.green
        
           cell.textLabel?.text = device.id
           cell.detailTextLabel?.text =
               device.isConnected ? "Connected" : "Available"

        return cell
    }
}

// MARK: - UITableViewDelegate
extension AvailableDevices_ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "BLE Devices"
    }
    
     func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        let device = BLEDeviceStore.shared.devices[indexPath.row]
        selectedDeviceID = device.id

        device.peripheral.delegate = self
        centralManager.connect(device.peripheral, options: nil)

    }
}

// MARK: - Write to ESP32
extension AvailableDevices_ViewController {
    func sendText(_ message: String) {
        guard let textRxChar = textRxChar,
              let peripheral = connectedPeripheral else { return }

        print("➡️ TEXT:", message)
        let data = message.data(using: .utf8)!
        peripheral.writeValue(data, for: textRxChar, type: .withResponse)
    }

}

extension Array where Element == LedsInfo {

    func toData() -> Data {
        var data = Data()
        data.reserveCapacity(self.count * 18)

        for led in self {

            var interval   = led.interval.littleEndian
            var candleBlue = led.candleBlue.littleEndian
            var candleRed    = led.candleRed.littleEndian
            var candleGreen    = led.candleGreen.littleEndian

            Swift.withUnsafeBytes(of: &interval) {
                data.append(contentsOf: $0)
            }

            Swift.withUnsafeBytes(of: &candleBlue) {
                data.append(contentsOf: $0)
            }

            data.append(led.baseBrightness)
            data.append(led.house)

            Swift.withUnsafeBytes(of: &candleRed) {
                data.append(contentsOf: $0)
            }

            Swift.withUnsafeBytes(of: &candleGreen) {
                data.append(contentsOf: $0)
            }
        }

        return data
    }
}

extension FixedWidthInteger {
    var littleEndianData: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<Self>.size)
    }
}
