//
//  MMTToolForNordicDFUDelegate.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 03/04/2026.
//

import Foundation

public protocol MMTToolForNordicDFUDelegate: NSObject {

    func mmtToolForGoodixUnitDidEnter(_ unit: MMTToolForGoodixDFUToolUnit?)
    func mmtToolForGoodixUnitDidFailToEnter(_ unit: MMTToolForGoodixDFUToolUnit?, error: Error?)
    func mmtToolForGoodixUnitDFUDidBegin(_ unit: MMTToolForGoodixDFUToolUnit?)
    func mmtToolForGoodixUnitDFUDidChangeProgress(_ unit: MMTToolForGoodixDFUToolUnit?, progress: Int)
    func mmtToolForGoodixUnitDFUDidEnd(_ unit: MMTToolForGoodixDFUToolUnit?, progress: Int?, error: Error?)
    func mmtToolForGoodixUnitDidShowErrorMessage(_ unit: MMTToolForGoodixDFUToolUnit?, stage: String?, error: Error?)

    typealias DFUServerTurple = (
        service: CBService?,
        readCharacter: CBCharacteristic?,
        writeCharacter: CBCharacteristic?,
        controlCharacter: CBCharacteristic?
    )
    func mmtToolForGoodixUnitGetUUID(_ unit: MMTToolForGoodixDFUToolUnit?) -> DFUServerTurple?

}
