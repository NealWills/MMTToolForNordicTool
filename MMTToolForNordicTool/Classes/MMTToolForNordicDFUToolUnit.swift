//
//  MMTToolForNordicDFUToolUnit.swift
//  MMTToolForNordicTool
//
//  Created by Maxeye_Neal on 03/04/2026.
//

import CoreBluetooth
import Foundation

public class MMTToolForNordicDFUToolUnit: NSObject {
    var unitId: String = UUID().uuidString

    public enum DFUStatus {
        case prepare
        case progress(_ current: Int, _ total: Int)
        case finish
        case error(_ error: Error)
    }

    public var dfuStatus: DFUStatus = .prepare

    enum DFUStage {
        case normal
        case sendDFUEnter
        case dfuModeReady
        case dfuStart
        case dfuSuccess
        case dfuFailure
        case dfuCancel

        var titleValue: String {
            switch self {
            case .normal:
                return "normal"
            case .sendDFUEnter:
                return "sendDFUEnter"
            case .dfuModeReady:
                return "dfuModeReady"
            case .dfuStart:
                return "dfuStart"
            case .dfuSuccess:
                return "dfuSuccess"
            case .dfuFailure:
                return "dfuFailure"
            case .dfuCancel:
                return "dfuCancel"
            }
        }
    }

    var dfuStage: DFUStage = .normal

    override public var description: String {
        var title = "" + "〖"
        title = title + " " + "id: " + String(format: "%p", self) + " " + " |"
        title = title + " " + "deviceMac: " + "\(deviceMac ?? "")" + " " + " |"
        title = title + " " + "deviceMac: " + "\(deviceMacExtra ?? "")" + " " + " |"
        title = title + " " + "deviceMac: " + "\(deviceUUID ?? "")" + " " + " |"
        title = title + " " + "dfuStatus: " + dfuStage.titleValue + " " + " |"
        title = title + " 〗 "
        return title
    }

    public var startTimeStamp: TimeInterval = 0

    public var deviceMac: String?

    public var deviceMacExtra: String?

    public var deviceUUID: String?

//    weak var delegate: MMTToolForNordicDFUDelegate?

    var startAddress: String?

    var dfuFilePath: String?

    fileprivate weak var service: CBService?

    fileprivate weak var readCharacter: CBCharacteristic?

    fileprivate weak var writeCharacter: CBCharacteristic?

    fileprivate weak var controlCharacter: CBCharacteristic?

    public var localServiceUUID: String?

    public var localReadCharacterUUID: String?

    public var localWriteCharacterUUID: String?

    public var localControlCharacterUUID: String?

    public var localPeripheral: CBPeripheral?

    ///    fileprivate var easyDfu2: EasyDfu2?
    fileprivate var initiator: DFUServiceInitiator?

    fileprivate var manager: CBCentralManager?

    fileprivate var peripheral: CBPeripheral?

    var timer: Timer?
    var timerValidTimestamp: TimeInterval = 0

    var currentProgress: Int = 0

    func startDfu() {
        dfuStage = .normal
        service = nil
        readCharacter = nil
        writeCharacter = nil
        controlCharacter = nil
        initiator?.delegate = nil
//        self.easyDfu2 = nil

        dfuStep01()
    }

    func destroyUnit() {
        manager?.delegate = nil
        manager = nil
//        self.easyDfu2 = EasyDfu2.init()
        destroyTimer()
    }

    var stepBlock: ((_ unitId: String?, _ stage: String) -> Void)?
    var progressBlock: ((_ unitId: String?, _ progress: Int) -> Void)?
    var resultBlock: ((_ unitId: String?, _ progress: Int?, _ error: NSError?) -> Void)?
    var dfuErrorMsgBlock: ((_ unitId: String?, _ errorMsg: String, _ stage: String) -> Void)?
}

extension MMTToolForNordicDFUToolUnit {
    // 1. 发送命令进入DFU模式

    func dfuStep01() {
        dfuStage = .sendDFUEnter
        guard let service = localPeripheral?.services?.first(where: {
            $0.uuid.uuidString.uppercased() == self.localServiceUUID
        }) else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device Service Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        guard let controlCharacter = service.characteristics?.first(where: {
            $0.uuid.uuidString.uppercased() == self.localControlCharacterUUID?.uppercased()
        }) else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device ControlCharacter Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }

        guard let startAddressStr = startAddress,
              let address = UInt32(startAddressStr, radix: 16)
        else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        guard let dfuFilePath = dfuFilePath else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        let url = URL(fileURLWithPath: dfuFilePath)
        guard let fileData = try? Data(contentsOf: url) else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }

        stepBlock?(unitId, "Dfu step01 [0x44, 0x4f, 0x4f, 0x47] send")

        localPeripheral?.writeValue(Data([0x44, 0x4F, 0x4F, 0x47]), for: controlCharacter, type: .withoutResponse)

        stepBlock?(unitId, "Dfu step01 stop scan")
        manager?.stopScan()
        manager = nil
        peripheral = nil

        manager = CBCentralManager()
        manager?.delegate = self

        dfuStage = .sendDFUEnter

        DispatchQueue(label: "com.mmt.sdk.Nordic").asyncAfter(deadline: .now() + 1) {
            self.stepBlock?(self.unitId, "Dfu step01 start scan")
            self.manager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        }

//        device.writeData(data: [0x44, 0x4f, 0x4f, 0x47], character: controlCharacter, type: .withoutResponse)

//        MMTToolForBleManager.shared.startScan(perfix: deviceName)
//        dfuStep02(peripheral: device.peripheral, dfuData: fileData, copyAddr: address)
    }

    func dfuStep02() {
        if dfuStage != .sendDFUEnter {
            return
        }
        stepBlock?(unitId, "Dfu step02 enter")
        dfuStage = .dfuModeReady

        guard let startAddressStr = startAddress,
              let address = UInt32(startAddressStr, radix: 16)
        else {
//            MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist"))
//            MMTToolForNordicDFUTool.share.unitList.remove(self)
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        guard let dfuFilePath = dfuFilePath else {
//            MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForNordicDFUTool.share.unitList.append(self)

            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        let url = URL(fileURLWithPath: dfuFilePath)
        guard let fileData = try? Data(contentsOf: url) else {
//            MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
//            MMTToolForNordicDFUTool.share.unitList.append(self)

            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(unitId, 0, error)

            return
        }

        guard let peripheral = peripheral else {
//            MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device Not Found"))
//            MMTToolForNordicDFUTool.share.unitList.append(self)

            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device Not Found")
            resultBlock?(unitId, 0, error)

            return
        }

        stepBlock?(unitId, "Dfu step02 init easy dfu2")
        dfuStage = .dfuStart

//        self.easyDfu2 = EasyDfu2.init()
//        self.easyDfu2?.setFastMode(isFastMode: false)
//        self.easyDfu2?.setListener(listener: self)
//        self.easyDfu2?.setReconnectScanFilter { [weak self] peripheral, advertisementData, rssi in
//            if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
//                let macList = macData.map({
//                    return String.init(format: "%02x", $0).uppercased()
//                })
//                var mac = macList.joined(separator: ":")
//                var macExtra: String?
//                if macList.count > 6 {
//                    mac = macList[0..<6].joined(separator: ":")
//                    macExtra = macList[6..<macList.count].joined(separator: ":")
//                }
//                if mac.uppercased() == self?.deviceMac?.uppercased() {
//                    return true
//                }
//                return false
//            }
//            return false
//        }

        stepBlock?(unitId, "Dfu step02 dfu2 startDfuInCopyMode")

//        self.easyDfu2?.startDfuInCopyMode(central: self.manager, target: peripheral, dfuData: fileData, copyAddr: address)

        currentProgress = 0
        stepBlock?(unitId, "Dfu step02 dfu2 start timer")

        timer?.invalidate()
        timer = nil
        timerValidTimestamp = Date().timeIntervalSince1970
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction(_:)), userInfo: nil, repeats: true)
    }

    @objc func timerAction(_: Any) {
        let currentDate = Date()
        let distance = currentDate.timeIntervalSince1970 - timerValidTimestamp
        if distance > 30 {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "dfu stop with error: DFU time out")
//            self.easyDfu2?.cancel()
            destroyTimer()
            resultBlock?(unitId, currentProgress, error)
        }
    }

    func destroyTimer() {
        timer?.invalidate()
        timer = nil
    }

//    func dfuStep02(peripheral: CBPeripheral) {
//
//        if self.dfuStage != .sendDFUEnter {
//            return
//        }
//
//        guard let startAddressStr = self.startAddress,
//              let address = UInt32(startAddressStr, radix:16)
//        else {
//            MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist"))
    ////            MMTToolForNordicDFUTool.share.unitList.remove(self)
//            return
//        }
//        guard let dfuFilePath = self.dfuFilePath else {
//            MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
    ////            MMTToolForNordicDFUTool.share.unitList.append(self)
//            return
//        }
//        let url = URL.init(fileURLWithPath: dfuFilePath)
//        guard let fileData = try? Data(contentsOf: url) else {
//            MMTToolForNordicDFUTool.sendDelegateUnitDFUDidEnd(self, error: MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist"))
    ////            MMTToolForNordicDFUTool.share.unitList.append(self)
//            return
//        }
//
//
//        self.dfuStage = .dfuModeReady
//
//        self.easyDfu2 = EasyDfu2.init()
//        self.easyDfu2?.setFastMode(isFastMode: false)
//        self.easyDfu2?.setListener(listener: self)
//        self.easyDfu2?.startDfuInCopyMode(central: nil, target: peripheral, dfuData: fileData, copyAddr: address)
//    }
}

extension MMTToolForNordicDFUToolUnit: DFUServiceDelegate {
    /**
     Callback called when state of the DFU Service has changed.

     This method is called in the `delegateQueue` specified in the
     ``DFUServiceInitiator/init(queue:delegateQueue:progressQueue:loggerQueue:centralManagerOptions:)``.

     - parameter state: The new state of the service.
     */
    @objc public func dfuStateDidChange(to state: DFUState) {
        switch state {
        // Service is connecting to the DFU target.
        // 正在连接
        case .connecting:
            break
        // DFU Service is initializing DFU operation.
        // 初始化中
        case .starting:
            break
        // DFU Service is switching the device to DFU mode.
        // 切换到DFU模式
        case .enablingDfuMode:
            break
        // DFU Service is uploading the firmware.
        // 上传中
        case .uploading:
            break
        // The DFU target is validating the firmware. This state occurs only in Legacy DFU.
        // 验证中
        case .validating:
            break
        // The iDevice is disconnecting or waiting for disconnection.
        // 断开中
        case .disconnecting:
            break
        // DFU operation is completed and successful.
        // 完成
        case .completed:
            break
        // DFU operation was aborted.
        // 取消
        case .aborted:
            break
        }
    }

    /**
     Called after an error occurred.

     The device will be disconnected and DFU operation has been cancelled.

     - note: When an error is received the DFU state will not change to ``DFUState/aborted``.

     This method is called in the `delegateQueue` specified in the
     ``DFUServiceInitiator/init(queue:delegateQueue:progressQueue:loggerQueue:centralManagerOptions:)``.

     - parameter error:   The error code.
     - parameter message: Error description.
     */
    @objc public func dfuError(_: DFUError, didOccurWithMessage _: String) {}
}

extension MMTToolForNordicDFUToolUnit: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
//
        guard let originManager = manager else {
            return
        }

        let idOrigin = String(format: "%p", originManager)
        let idManager = String(format: "%p", central)
        if idOrigin != idManager { return }

        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: nil)
        default:
            break
        }
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi _: NSNumber) {
        if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let macList = macData.map {
                String(format: "%02x", $0).uppercased()
            }
            var mac = macList.joined(separator: ":")
            var macExtra: String?
            if macList.count > 6 {
                mac = macList[0 ..< 6].joined(separator: ":")
                macExtra = macList[6 ..< macList.count].joined(separator: ":")
            }
            if mac.uppercased() == deviceMac?.uppercased() {
                self.peripheral = peripheral

                stepBlock?(unitId, "Dfu step01 device scan success")
                stepBlock?(unitId, "Dfu step01 device scan success than end scan")

                central.stopScan()
                dfuStep02()
            }
        }
    }
}
