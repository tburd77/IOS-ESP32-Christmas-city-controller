//
//  Globals.swift
//  Christmas Light Controller
//
//  Created by Terry Burdett on 12/13/25.
//

import Foundation
import UIKit
import CoreBluetooth


let TEXT_RX_UUID = CBUUID(string: "12345678-1234-1234-1234-1234567890CF")
let DATA_RX_UUID = CBUUID(string: "12345678-1234-1234-1234-1234567890CD")
let TEXT_TX_UUID = CBUUID(string: "12345678-1234-1234-1234-1234567890BB")
let DATA_TX_UUID = CBUUID(string: "12345678-1234-1234-1234-1234567890BA")
let ID_CHAR_UUID = CBUUID(string: "12345678-1234-1234-1234-1234567890CE")
let SERVICE_UUID = CBUUID(string: "12345678-1234-1234-1234-1234567890CA")

var bleSendText = ""

struct BLEDevice {
    let id: String
    var peripheral: CBPeripheral
    var isConnected: Bool
}

struct LedsInfo {
    var interval: UInt32
    var candleBlue: UInt32
    var baseBrightness: UInt8
    var house: UInt8
    var candleRed: Int32
    var candleGreen: Int32
}

let ledsInfoSize = MemoryLayout<LedsInfo>.size  // = 18
var ledsInfo_Array = [LedsInfo]()
var led_Selected = 0
