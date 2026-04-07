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
    
    fileprivate var controller: DFUServiceController?
    
    fileprivate var selector: DFUServiceSelector?

    fileprivate var manager: CBCentralManager?

    fileprivate var peripheral: CBPeripheral?
    
    fileprivate lazy var queue: DispatchQueue = {
        let queue = DispatchQueue(label: "com.mmt.nordic.queue")
        return queue
    }()
    
    fileprivate var delegateQueue: DispatchQueue = {
        let delegateQueue = DispatchQueue(label: "com.mmt.nordic.delegateQueue")
        return delegateQueue
    }()
    
    fileprivate var progressQueue: DispatchQueue = {
        let progressQueue = DispatchQueue(label: "com.mmt.nordic.progressQueue")
        return progressQueue
    }()
    
    fileprivate var loggerQueue: DispatchQueue = {
        let loggerQueue = DispatchQueue(label: "com.mmt.nordic.loggerQueue")
        return loggerQueue
    }()

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
        initiator?.progressDelegate = nil
        initiator = nil
        controller = nil
        selector = nil

        dfuStep01()
    }

    func destroyUnit() {
        manager?.delegate = nil
        manager = nil
        initiator = nil
        controller = nil
        selector = nil
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
//        guard let service = localPeripheral?.services?.first(where: {
//            $0.uuid.uuidString.uppercased() == self.localServiceUUID
//        }) else {
//            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device Service Not Exist")
//            resultBlock?(unitId, 0, error)
//            return
//        }
//        guard let controlCharacter = service.characteristics?.first(where: {
//            $0.uuid.uuidString.uppercased() == self.localControlCharacterUUID?.uppercased()
//        }) else {
//            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device ControlCharacter Not Exist")
//            resultBlock?(unitId, 0, error)
//            return
//        }

//        guard let startAddressStr = startAddress,
//              let address = UInt32(startAddressStr, radix: 16)
//        else {
//            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Start Address Not Exist")
//            resultBlock?(unitId, 0, error)
//            return
//        }
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

//        stepBlock?(unitId, "Dfu step01 [0x44, 0x4f, 0x4f, 0x47] send")

        // 发送进入 DFU 模式的命令 nordic 不需要做这个
//        localPeripheral?.writeValue(Data([0x44, 0x4F, 0x4F, 0x47]), for: controlCharacter, type: .withoutResponse)

        stepBlock?(unitId, "Dfu step01 stop scan")
        manager?.stopScan()
        manager = nil
        peripheral = nil

        manager = CBCentralManager()
        manager?.delegate = self
            
        guard let uuid = localPeripheral?.identifier else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        
        dfuStage = .sendDFUEnter
        self.peripheral = localPeripheral
        
        self.dfuStep02()
        
//        let list = manager?.retrievePeripherals(withIdentifiers: [uuid])
//        if (list?.count ?? 0) > 0 {
//            
//            dfuStage = .sendDFUEnter
//            self.peripheral = localPeripheral
//            self.dfuStep02()
//        } else {
//            
//            dfuStage = .sendDFUEnter
//                
//            self.manager?.stopScan()
//
//            DispatchQueue(label: "com.mmt.sdk.Nordic").asyncAfter(deadline: .now() + 1) {
//                self.stepBlock?(self.unitId, "Dfu step01 start scan")
//                self.manager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
//            }
//        }


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
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU Device Not Found")
            resultBlock?(unitId, 0, error)
            return
        }

        guard let manager = manager else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "Central Manager Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }

        stepBlock?(unitId, "Dfu step02 init DFU initiator")
        dfuStage = .dfuStart
        
        guard let fireware = try? DFUFirmware(zipFile: fileData) else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        
        
        // 使用已有的 centralManager 和 peripheral 初始化 DFU 服务启动器
//        let initiator = DFUServiceInitiator(centralManager: manager, target: peripheral)
        let initiator = DFUServiceInitiator
            .init(
                queue: queue,
                delegateQueue: delegateQueue,
                progressQueue: progressQueue,
                loggerQueue: loggerQueue
            )
            .with(firmware: fireware)
        initiator.delegate = self
        initiator.progressDelegate = self
        initiator.logger = self  // 设置日志代理
        self.initiator = initiator
        
        guard let controller = initiator.start(target: peripheral) else {
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU File Not Exist")
            resultBlock?(unitId, 0, error)
            return
        }
        self.controller = controller
        
        // 创建 DFU 选择器并启动
        let selector = DFUServiceSelector(initiator: initiator, controller: controller)
        self.selector = selector

        stepBlock?(unitId, "Dfu step02 start DFU selector")

        // 启动 DFU 升级流程
        selector.start()

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

}


extension MMTToolForNordicDFUToolUnit: DFUProgressDelegate {
    
    /// DFU 进度变化回调
    /// - Parameters:
    ///   - part: 当前部分编号
    ///   - totalParts: 总部分数
    ///   - progress: 进度百分比 (0-100)
    ///   - currentSpeedBytesPerSecond: 当前传输速度（字节/秒）
    ///   - avgSpeedBytesPerSecond: 平均传输速度（字节/秒）
    public func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        // 更新当前进度
        currentProgress = progress
        
        // 记录进度日志
        MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU Progress: \(progress)%, Part: \(part)/\(totalParts), Speed: \(currentSpeedBytesPerSecond) B/s", level: .info)
        
        // 通过回调通知进度更新
        progressBlock?(unitId, progress)
        
        // 更新时间戳，防止超时
        timerValidTimestamp = Date().timeIntervalSince1970
    }
    
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
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Connecting", level: .info)
            stepBlock?(unitId, "DFU State: Connecting")
            dfuStage = .dfuModeReady
            
        // DFU Service is initializing DFU operation.
        // 初始化中
        case .starting:
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Starting", level: .info)
            stepBlock?(unitId, "DFU State: Starting")
            
        // DFU Service is switching the device to DFU mode.
        // 切换到DFU模式
        case .enablingDfuMode:
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Enabling DFU Mode", level: .info)
            stepBlock?(unitId, "DFU State: Enabling DFU Mode")
            
        // DFU Service is uploading the firmware.
        // 上传中
        case .uploading:
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Uploading", level: .info)
            stepBlock?(unitId, "DFU State: Uploading")
            dfuStage = .dfuStart
            
        // The DFU target is validating the firmware. This state occurs only in Legacy DFU.
        // 验证中
        case .validating:
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Validating", level: .info)
            stepBlock?(unitId, "DFU State: Validating")
            
        // The iDevice is disconnecting or waiting for disconnection.
        // 断开中
        case .disconnecting:
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Disconnecting", level: .info)
            stepBlock?(unitId, "DFU State: Disconnecting")
            
        // DFU operation is completed and successful.
        // 完成
        case .completed:
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Completed", level: .info)
            stepBlock?(unitId, "DFU State: Completed")
            dfuStage = .dfuSuccess
            
            self.currentProgress = 100
            
            // 销毁定时器
            destroyTimer()
            
            // 通知 DFU 完成
            resultBlock?(unitId, 100, nil)
            
        // DFU operation was aborted.
        // 取消
        case .aborted:
            MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU State: Aborted", level: .info)
            stepBlock?(unitId, "DFU State: Aborted")
            dfuStage = .dfuCancel
            
            // 销毁定时器
            destroyTimer()
            
            // 通知 DFU 取消
            let error = MMTToolForNordicDFUTool.createError(code: -1, localDescrip: "DFU was aborted")
            resultBlock?(unitId, currentProgress, error)
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
    @objc public func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        MMTToolForNordicLog.log("[MMTToolForNordicDFUToolUnit] DFU Error: \(error.rawValue) - \(message)", level: .error)
        
        dfuStage = .dfuFailure
        
        // 销毁定时器
        destroyTimer()
        
        // 创建错误对象
        let nsError = MMTToolForNordicDFUTool.createError(code: error.rawValue, localDescrip: message)
        
        // 通过错误消息回调通知
        dfuErrorMsgBlock?(unitId, message, "DFU Error")
        
        // 通知 DFU 失败
        resultBlock?(unitId, currentProgress, nsError)
    }
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

// MARK: - LoggerDelegate

extension MMTToolForNordicDFUToolUnit: LoggerDelegate {
    
    /// 日志输出回调
    public func logWith(_ level: LogLevel, message: String) {
        let levelString: String
        switch level {
        case .debug:
            levelString = "DEBUG"
        case .verbose:
            levelString = "VERBOSE"
        case .info:
            levelString = "INFO"
        case .application:
            levelString = "APPLICATION"
        case .warning:
            levelString = "WARNING"
        case .error:
            levelString = "ERROR"
        @unknown default:
            levelString = "UNKNOWN"
        }
        
        MMTToolForNordicLog.log("[Nordic DFU][\(levelString)] \(message)", level: .info)
    }
}
