//
//  BLEDeviceStore.swift
//  Christmas Light Controller
//
//  Created by Terry Burdett on 12/17/25.
//


import CoreBluetooth

final class BLEDeviceStore {

    static let shared = BLEDeviceStore()

    private(set) var devices: [BLEDevice] = []

    func upsert(
        peripheral: CBPeripheral,
        id: String
    ) {
        if let index = devices.firstIndex(where: { $0.id == id }) {
            devices[index].peripheral = peripheral
        } else {
            devices.append(
                BLEDevice(
                    id: id,
                    peripheral: peripheral,
                    isConnected: false
                )
            )
        }
    }

    func setConnectionState(
        _ peripheral: CBPeripheral,
        connected: Bool
    ) {
        guard let index = devices.firstIndex(
            where: { $0.peripheral == peripheral }
        ) else { return }

        devices[index].isConnected = connected
    }
}
