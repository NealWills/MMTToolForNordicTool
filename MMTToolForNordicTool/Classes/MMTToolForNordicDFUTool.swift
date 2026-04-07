//
//  MMTToolForNordicDFUTool.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 03/04/2026.
//


import Foundation
import CoreBluetooth

class MMTToolForNordicWeakDelegateUnit: NSObject {
    weak var weakDelegate: MMTToolForNordicDFUDelegate?
    
    init(weakDelegate: MMTToolForNordicDFUDelegate? = nil) {
        self.weakDelegate = weakDelegate
    }
}

public protocol MMTToolForNordicDFUDelegate: NSObject {

    func mmtToolForNordicUnitDidEnter(_ unit: MMTToolForNordicDFUToolUnit?)
    func mmtToolForNordicUnitDidFailToEnter(_ unit: MMTToolForNordicDFUToolUnit?, error: Error?)
    func mmtToolForNordicUnitDFUDidBegin(_ unit: MMTToolForNordicDFUToolUnit?)
    func mmtToolForNordicUnitDFUDidChangeProgress(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int)
    func mmtToolForNordicUnitDFUDidEnd(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int?, error: Error?)
    func mmtToolForNordicUnitDidShowErrorMessage(_ unit: MMTToolForNordicDFUToolUnit?, stage: String?, error: Error?)

    typealias DFUServerTurple = (
        service: CBService?,
        readCharacter: CBCharacteristic?,
        writeCharacter: CBCharacteristic?,
        controlCharacter: CBCharacteristic?
    )
    func mmtToolForNordicUnitGetUUID(_ unit: MMTToolForNordicDFUToolUnit?) -> DFUServerTurple?
    
    func mmtToolForNordicUnitGetPeripheral(_ unit: MMTToolForNordicDFUToolUnit?) -> CBPeripheral?

}

public class MMTToolForNordicDFUTool: NSObject {

    static let share = MMTToolForNordicDFUTool()
    var multiDelegateList: [MMTToolForNordicWeakDelegateUnit] = .init()
    var unitList: [MMTToolForNordicDFUToolUnit] = .init()
    
    public class func configManager() {
        MMTToolForNordicDFUFileManager.removeTempDir()
    }
    
    public class func startDfu(deviceUUID: String?, deviceMac: String?, deviceMacExtra: String?, peripheral: CBPeripheral?, startAddress: String?, filePath: String?) {
        let unit = MMTToolForNordicDFUToolUnit.init()
        
        guard let deviceUUID = deviceUUID,
              let deviceMac = deviceMac,
              let deviceMacExtra = deviceMacExtra,
              let peripheral = peripheral
        else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device Not Exist"))
            return
        }
        
        unit.deviceMac = deviceMac.uppercased()
        unit.deviceMacExtra = deviceMacExtra.uppercased()
        unit.deviceUUID = deviceUUID
        unit.localPeripheral = peripheral
        
        guard let filePath = filePath else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        
        if filePath.count < 4 {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        unit.dfuFilePath = filePath
        
        let isExist = FileManager.default.fileExists(atPath: filePath)
        if !isExist {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
            return
        }
        MMTToolForNordicDFUFileManager.copyDFUFileToTempDir(originPath: filePath, deviceMac: deviceMac)
        guard let startAddress = startAddress else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Start Address Unit Not Exist"))
            return
        }
        unit.startAddress = startAddress
        
        let isContain = MMTToolForNordicDFUTool.share.unitList.contains(where: {
            return $0.deviceMac?.uppercased() == deviceMac.uppercased()
        }) ?? false
        if isContain {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Unit Exist"))
            return
        }
        guard let turple = MMTToolForNordicDFUTool.sendDelegateUnitDFUGetUUID(unit) else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Delegate Not Exist"))
            return
        }
        guard let service = turple.service else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Service Not Exist"))
            return
        }
        guard let readCharacter = turple.readCharacter else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "ReadCharacter Not Exist"))
            return
        }
        guard let writeCharacter = turple.writeCharacter else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "WriteCharacter Not Exist"))
            return
        }
        guard let controlCharacter = turple.controlCharacter else {
            MMTToolForNordicDFUTool.sendDelegateUnitDidFailToEnter(unit, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "ControlCharacter Not Exist"))
            return
        }
        unit.localServiceUUID = service.uuid.uuidString.uppercased()
        unit.localReadCharacterUUID = readCharacter.uuid.uuidString.uppercased()
        unit.localWriteCharacterUUID = writeCharacter.uuid.uuidString.uppercased()
        unit.localControlCharacterUUID = controlCharacter.uuid.uuidString.uppercased()
        unit.startTimeStamp = Date().timeIntervalSince1970
        MMTToolForNordicDFUTool.share.unitList.append(unit)
        MMTToolForNordicDFUTool.sendDelegateUnitDidEnter(unit)
        
        unit.dfuErrorMsgBlock = { unitId, msg, stage in
            if let toolUnit = MMTToolForNordicDFUTool.share.unitList.first(where: {
                return $0.unitId == unitId
            }) {
//                MMTToolForNordicLog.log("[MMTToolForNordicLog] sendDelegateUnitDFUDidChangeProgress progress: \(progress)", level: .info)
                let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: msg)
                MMTToolForNordicDFUTool.sendDelegateUnitDFUDidShowErrorMessage(unit, stage: stage, error: error)
            }
        }
        
        unit.progressBlock = { unitId, progress in
            if let toolUnit = MMTToolForNordicDFUTool.share.unitList.first(where: {
                return $0.unitId == unitId
            }) {
                MMTToolForNordicLog.log("[MMTToolForNordicLog] sendDelegateUnitDFUDidChangeProgress progress: \(progress)", level: .info)
                MMTToolForNordicDFUTool.sendDelegateUnitDFUDidChangeProgress(toolUnit, progress: progress)
            }
        }
        
        unit.resultBlock = { unitId, progress, error in
            if let toolUnit = MMTToolForNordicDFUTool.share.unitList.first(where: {
                return $0.unitId == unitId
            }) {
                
                MMTToolForNordicLog.log("[MMTToolForNordicLog] sendDelegateUnitDFUDidEnd error: \(error)", level: .info)
                
                MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(toolUnit, progress: progress, error: error)
                
                toolUnit.destroyUnit()
                
                MMTToolForNordicDFUTool.share.unitList.removeAll {
                    return $0.unitId == unitId
                }
            }
        }
        
        unit.startDfu()
        
        MMTToolForNordicLog.log("[MEOTANordicManager] mmtToolForNordicUnit Did Start DFU")
    }
    
}

public extension MMTToolForNordicDFUTool {
    
    class func addDelegate(_ delegate: MMTToolForNordicDFUDelegate?) {
        guard let delegate = delegate else { return }
        let delegateId = String.init(format: "%p", delegate)
        var list = MMTToolForNordicDFUTool.share.multiDelegateList
        list = list.filter {
            return $0.weakDelegate != nil
        }
        if list.contains(where: {
            if let item = $0.weakDelegate {
                let id0 = String.init(format: "%p", item)
                return id0 == delegateId
            }
            return false
        }) {
            return
        }
        let delegateUnit = MMTToolForNordicWeakDelegateUnit.init(weakDelegate: delegate)
        list.append(delegateUnit)
        MMTToolForNordicDFUTool.share.multiDelegateList = list
    }
    
    class func removeDelegate(_ delegate: MMTToolForNordicDFUDelegate?) {
        guard let delegate = delegate else { return }
        let delegateId = String.init(format: "%p", delegate)
        var list = MMTToolForNordicDFUTool.share.multiDelegateList
        list = list.filter {
            guard let item = $0.weakDelegate else {
                return false
            }
            let id0 = String.init(format: "%p", item)
            return id0 != delegateId
        }
        MMTToolForNordicDFUTool.share.multiDelegateList = list
    }
    
    class func sendDelegateUnitDidEnter(_ unit: MMTToolForNordicDFUToolUnit?) {
        let list = MMTToolForNordicDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForNordicUnitDidEnter(unit)
        })
    }
    
    class func sendDelegateUnitDidFailToEnter(_ unit: MMTToolForNordicDFUToolUnit?, error: Error?) {
        let list = MMTToolForNordicDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForNordicUnitDidFailToEnter(unit, error: error)
        })
    }
    
    class func sendDelegateUnitDFUDidBegin(_ unit: MMTToolForNordicDFUToolUnit?) {
        let list = MMTToolForNordicDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForNordicUnitDFUDidBegin(unit)
        })
    }
    
    class func sendDelegateUnitDFUDidChangeProgress(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int) {
        let list = MMTToolForNordicDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForNordicUnitDFUDidChangeProgress(unit, progress: progress)
        })
        
    }
    
    class func sendDelegateUnitDFUDidEnd(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int?, error: Error?) {
        let list = MMTToolForNordicDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForNordicUnitDFUDidEnd(unit, progress: progress, error: error)
        })
        
    }
    
    class func sendDelegateUnitDFUDidShowErrorMessage(_ unit: MMTToolForNordicDFUToolUnit?, stage: String?, error: Error?) {
        let list = MMTToolForNordicDFUTool.share.multiDelegateList
        list.forEach({
            $0.weakDelegate?.mmtToolForNordicUnitDidShowErrorMessage(unit, stage: stage, error: error)
        })
        
    }
    
    class func sendDelegateUnitDFUGetUUID(_ unit: MMTToolForNordicDFUToolUnit?) -> MMTToolForNordicDFUDelegate.DFUServerTurple? {
        let list = MMTToolForNordicDFUTool.share.multiDelegateList
        let turpleList: [MMTToolForNordicDFUDelegate.DFUServerTurple?] = list.map({
            return $0.weakDelegate?.mmtToolForNordicUnitGetUUID(unit)
        }).filter({
            return $0 != nil
        })
        return turpleList.first ?? nil
    }
    
    class func createError(code: Int, localDescrip: String) -> NSError {
        var userInfo: [String : Any] = .init()
        userInfo[NSLocalizedDescriptionKey] = localDescrip
        let error = NSError(domain: "com.mmt.sdk.NordicDFUTool.error", code: code, userInfo: userInfo)
        return error
    }
    
}
