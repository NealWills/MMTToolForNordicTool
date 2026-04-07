//
//  ViewController.swift
//  MMTToolForNordicTool
//
//  Created by NealWills on 04/03/2026.
//  Copyright (c) 2026 NealWills. All rights reserved.
//

import UIKit
import CoreBluetooth
import MMTToolForNordicTool

class ViewController: UIViewController {

    // MARK: - UI Components

    /// Scan button - Used to start/stop scanning Bluetooth devices
    private lazy var scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Scan", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        return button
    }()

    /// Device list table - Displays scanned Bluetooth devices
    private lazy var deviceTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DeviceCell.self, forCellReuseIdentifier: DeviceCell.identifier)
        tableView.isHidden = true
        tableView.backgroundColor = .systemBackground
        tableView.separatorColor = .separator
        return tableView
    }()

    /// Status label - Displays current operation status
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready"
        label.textAlignment = .center
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    /// Selected device info container view
    private lazy var selectedDeviceView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    /// Selected device name label
    private lazy var selectedDeviceNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        return label
    }()

    /// Selected device MAC address label
    private lazy var selectedMACLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Connection status label - Displays "Connected" or "Disconnected"
    private lazy var connectionStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .right
        return label
    }()

    /// Connect/Disconnect button
    private lazy var connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Connect Device", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    /// DFU upgrade button
    private lazy var dfuButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start DFU", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.addTarget(self, action: #selector(dfuButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    // MARK: - Command Log Container

    /// Command log container view
    private lazy var commandContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    /// Command log title label
    private lazy var commandTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Command Log"
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .label
        return label
    }()

    /// Command log text view - Displays operation logs
    private lazy var commandTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.textColor = .label
        textView.backgroundColor = .tertiarySystemBackground
        textView.layer.cornerRadius = 8
        textView.isEditable = false
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return textView
    }()

    /// Clear log button
    private lazy var clearLogButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.addTarget(self, action: #selector(clearLogButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties

    /// Bluetooth central manager
    private var centralManager: CBCentralManager!

    /// Discovered devices list
    private var discoveredDevices: [CBPeripheral] = []

    /// Device MAC address mapping - UUID -> (MAC address, extra data)
    private var deviceMACMap: [UUID: (mac: String, macExtra: String?)] = [:]

    /// Device name mapping - UUID -> Device name
    private var deviceNameMap: [UUID: String] = [:]

    /// Device RSSI mapping - UUID -> RSSI value
    private var deviceRSSIMap: [UUID: NSNumber] = [:]

    /// MAC to device ID mapping for deduplication
    private var macToDeviceMap: [String: UUID] = [:]

    /// Currently selected device
    private var selectedDevice: CBPeripheral?

    /// Connection status
    private var isConnected: Bool = false

    /// Discovered services list
    private var discoveredServices: [CBService] = []

    /// Service characteristics mapping - Service UUID -> Characteristics array
    private var serviceCharacteristicsMap: [CBUUID: [CBCharacteristic]] = [:]

    /// Selected firmware file URL
    private var selectedFirmwareURL: URL?

    // MARK: - Lifecycle

    /// View did load
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBluetooth()
        setupNavigationBar()
        setupLogger()

        // Configure DFU tool
        MMTToolForNordicDFUTool.configManager()
    }

    /// View will disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    /// Deinitializer
    deinit {
        MMTToolForNordicDFUTool.removeDelegate(self)
    }

    // MARK: - UI 设置

    /// 设置UI界面
    private func setupUI() {
        view.backgroundColor = .systemBackground

        // MARK: - 设置选中设备信息展示区域
        selectedDeviceView.addSubview(selectedDeviceNameLabel)
        selectedDeviceView.addSubview(selectedMACLabel)
        selectedDeviceView.addSubview(connectionStatusLabel)

        selectedDeviceNameLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedMACLabel.translatesAutoresizingMaskIntoConstraints = false
        connectionStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            selectedDeviceNameLabel.topAnchor.constraint(equalTo: selectedDeviceView.topAnchor, constant: 12),
            selectedDeviceNameLabel.leadingAnchor.constraint(equalTo: selectedDeviceView.leadingAnchor, constant: 16),
            selectedDeviceNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: connectionStatusLabel.leadingAnchor, constant: -8),

            connectionStatusLabel.centerYAnchor.constraint(equalTo: selectedDeviceNameLabel.centerYAnchor),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: selectedDeviceView.trailingAnchor, constant: -16),

            selectedMACLabel.topAnchor.constraint(equalTo: selectedDeviceNameLabel.bottomAnchor, constant: 8),
            selectedMACLabel.leadingAnchor.constraint(equalTo: selectedDeviceView.leadingAnchor, constant: 16),
            selectedMACLabel.trailingAnchor.constraint(lessThanOrEqualTo: selectedDeviceView.trailingAnchor, constant: -16),
            selectedMACLabel.bottomAnchor.constraint(equalTo: selectedDeviceView.bottomAnchor, constant: -12)
        ])

        // MARK: - 设置指令展示容器
        commandContainerView.addSubview(commandTitleLabel)
        commandContainerView.addSubview(commandTextView)
        commandContainerView.addSubview(clearLogButton)

        commandTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        commandTextView.translatesAutoresizingMaskIntoConstraints = false
        clearLogButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            commandTitleLabel.topAnchor.constraint(equalTo: commandContainerView.topAnchor, constant: 12),
            commandTitleLabel.leadingAnchor.constraint(equalTo: commandContainerView.leadingAnchor, constant: 16),

            clearLogButton.centerYAnchor.constraint(equalTo: commandTitleLabel.centerYAnchor),
            clearLogButton.trailingAnchor.constraint(equalTo: commandContainerView.trailingAnchor, constant: -16),

            commandTextView.topAnchor.constraint(equalTo: commandTitleLabel.bottomAnchor, constant: 8),
            commandTextView.leadingAnchor.constraint(equalTo: commandContainerView.leadingAnchor, constant: 16),
            commandTextView.trailingAnchor.constraint(equalTo: commandContainerView.trailingAnchor, constant: -16),
            commandTextView.bottomAnchor.constraint(equalTo: commandContainerView.bottomAnchor, constant: -12)
        ])

        // MARK: - 按钮区域容器
        let buttonStackView = UIStackView(arrangedSubviews: [scanButton, connectButton, dfuButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        // MARK: - 设备列表区域容器
        let listContainerView = UIView()
        listContainerView.translatesAutoresizingMaskIntoConstraints = false
        listContainerView.addSubview(statusLabel)
        listContainerView.addSubview(selectedDeviceView)
        listContainerView.addSubview(deviceTableView)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        selectedDeviceView.translatesAutoresizingMaskIntoConstraints = false
        deviceTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: listContainerView.topAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: listContainerView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: listContainerView.trailingAnchor),

            selectedDeviceView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),
            selectedDeviceView.leadingAnchor.constraint(equalTo: listContainerView.leadingAnchor),
            selectedDeviceView.trailingAnchor.constraint(equalTo: listContainerView.trailingAnchor),

            deviceTableView.topAnchor.constraint(equalTo: selectedDeviceView.bottomAnchor, constant: 8),
            deviceTableView.leadingAnchor.constraint(equalTo: listContainerView.leadingAnchor),
            deviceTableView.trailingAnchor.constraint(equalTo: listContainerView.trailingAnchor),
            deviceTableView.bottomAnchor.constraint(equalTo: listContainerView.bottomAnchor)
        ])

        // MARK: - 主布局
        let mainStackView = UIStackView(arrangedSubviews: [
            listContainerView,
            buttonStackView,
            commandContainerView
        ])
        mainStackView.axis = .vertical
        mainStackView.spacing = 16
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            scanButton.heightAnchor.constraint(equalToConstant: 44),
            connectButton.heightAnchor.constraint(equalToConstant: 44),
            dfuButton.heightAnchor.constraint(equalToConstant: 44),
            deviceTableView.heightAnchor.constraint(equalToConstant: 200),
            commandTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            mainStackView.heightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor, constant: -40)
        ])
    }
    
    // MARK: - 蓝牙设置

    /// 初始化蓝牙中心管理器
    private func setupBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// 设置导航栏
    private func setupNavigationBar() {
        title = "Nordic 工具"

        // 添加选择文件按钮
        let selectFileButton = UIBarButtonItem(
            title: "选择文件",
            style: .plain,
            target: self,
            action: #selector(selectFileButtonTapped)
        )
        navigationItem.rightBarButtonItem = selectFileButton
    }

    /// 设置日志系统
    private func setupLogger() {
        // 配置 Nordic DFU 日志系统
        MMTToolForNordicLog.configure { config in
            // 设置最低日志级别
            config.minimumLevel = .debug
            
            // 启用控制台输出
            config.enableConsole = true
            
            // 启用日志缓存
            config.cacheEnabled = true
            config.cacheLimit = 500
            
            // 启用颜色输出
            config.enableColors = true
        }
        
        // 设置自定义日志处理器，将日志输出到 UI
        MMTToolForNordicLog.setCustomHandler { [weak self] entry in
            guard let self = self else { return }
            
            // 在主线程更新 UI
            DispatchQueue.main.async {
                // 使用简化的日志格式
                let logMessage = entry.simplifiedMessage
                self.addLogToUI(logMessage)
            }
        }
    }
    
    /// 添加日志到 UI（内部方法）
    private func addLogToUI(_ message: String) {
        commandContainerView.isHidden = false
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        commandTextView.text += logMessage
        
        // 滚动到底部
        let range = NSRange(location: commandTextView.text.count - 1, length: 1)
        commandTextView.scrollRangeToVisible(range)
    }

    // MARK: - 按钮动作

    /// 扫描按钮点击事件 - 开始/停止扫描
    @objc private func scanButtonTapped(_ sender: UIButton) {
        if sender.currentTitle == "开始扫描" {
            startScanning()
        } else {
            stopScanning()
        }
    }

    /// 连接按钮点击事件 - 连接/断开设备
    @objc private func connectButtonTapped(_ sender: UIButton) {
        guard let device = selectedDevice else { return }

        if isConnected {
            // 断开连接
            centralManager.cancelPeripheralConnection(device)
            updateStatus("正在断开连接...")
            addLog("主动断开连接")
        } else {
            // 连接设备
            centralManager.connect(device, options: nil)
            let name = deviceNameMap[device.identifier] ?? "未知设备"
            let mac = deviceMACMap[device.identifier]?.mac ?? "未知"
            updateStatus("正在连接 \(name)...")
            addLog("开始连接设备: \(name) [\(mac)]")
        }
    }

    /// DFU按钮点击事件 - 预留功能
    @objc private func dfuButtonTapped(_ sender: UIButton) {
        // TODO: 实现 DFU 功能
        showDFUAlert()
    }

    /// 清除日志按钮点击事件
    @objc private func clearLogButtonTapped() {
        commandTextView.text = ""
        commandContainerView.isHidden = true
    }

    /// 选择文件按钮点击事件
    @objc private func selectFileButtonTapped() {
        let documentPicker = UIDocumentPickerViewController(
            documentTypes: ["public.data", "public.content"],
            in: .import
        )
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        documentPicker.modalPresentationStyle = .formSheet
        present(documentPicker, animated: true)
    }

    // MARK: - 蓝牙操作

    /// 开始扫描蓝牙设备
    private func startScanning() {
        guard centralManager.state == .poweredOn else {
            updateStatus("蓝牙未开启")
            return
        }
        
        discoveredDevices.removeAll()
        deviceMACMap.removeAll()
        deviceNameMap.removeAll()
        deviceRSSIMap.removeAll()
        macToDeviceMap.removeAll()
        deviceTableView.reloadData()
        deviceTableView.isHidden = false
        
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        scanButton.setTitle("停止扫描", for: .normal)
        scanButton.backgroundColor = .systemRed
        updateStatus("正在扫描设备...")
        addLog("开始扫描蓝牙设备")
    }

    /// 停止扫描蓝牙设备
    private func stopScanning() {
        centralManager.stopScan()
        scanButton.setTitle("开始扫描", for: .normal)
        scanButton.backgroundColor = .systemBlue
        updateStatus("已停止扫描")
        addLog("停止扫描，发现 \(discoveredDevices.count) 个设备")
    }

    // MARK: - UI 更新

    /// 更新状态标签
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }

    /// 添加日志到日志文本视图
    /// 添加日志（便捷方法）
    private func addLog(_ message: String) {
        // 使用新的日志系统
        MMTLogInfo(message)
    }

    /// 更新连接按钮状态和样式
    private func updateConnectButton(enabled: Bool, isConnected: Bool = false) {
        connectButton.isEnabled = enabled
        connectButton.alpha = enabled ? 1.0 : 0.5

        if isConnected {
            connectButton.setTitle("断开连接", for: .normal)
            connectButton.backgroundColor = .systemRed
        } else {
            connectButton.setTitle("连接设备", for: .normal)
            connectButton.backgroundColor = .systemGreen
        }
    }

    /// 更新DFU按钮状态
    private func updateDFUButton(enabled: Bool) {
        DispatchQueue.main.async {
            self.dfuButton.isEnabled = enabled
            self.dfuButton.alpha = enabled ? 1.0 : 0.5
        }
    }

    /// 根据连接状态和文件选择状态更新 DFU 按钮
    private func updateDFUButtonState() {
        let shouldEnable = isConnected && selectedFirmwareURL != nil
        updateDFUButton(enabled: shouldEnable)
    }

    /// 更新选中设备信息展示
    private func updateSelectedDeviceInfo() {
        DispatchQueue.main.async {
            guard let device = self.selectedDevice else {
                self.selectedDeviceView.isHidden = true
                return
            }
            
            self.selectedDeviceView.isHidden = false
            let name = self.deviceNameMap[device.identifier] ?? "未知设备"
            let macInfo = self.deviceMACMap[device.identifier]
            
            self.selectedDeviceNameLabel.text = name
            
            if let mac = macInfo?.mac {
                var macText = "MAC: \(mac)"
                if let extra = macInfo?.macExtra {
                    macText += "\nExtra: \(extra)"
                }
                self.selectedMACLabel.text = macText
            } else {
                self.selectedMACLabel.text = "MAC: 未知"
            }
            
            if self.isConnected {
                self.connectionStatusLabel.text = "已连接"
                self.connectionStatusLabel.textColor = .systemGreen
            } else {
                self.connectionStatusLabel.text = "未连接"
                self.connectionStatusLabel.textColor = .systemOrange
            }
        }
    }

    /// 按RSSI信号强度降序排列设备列表
    private func sortDevicesByRSSI() {
        discoveredDevices.sort { device1, device2 in
            let rssi1 = deviceRSSIMap[device1.identifier]?.intValue ?? Int.min
            let rssi2 = deviceRSSIMap[device2.identifier]?.intValue ?? Int.min
            return rssi1 > rssi2  // 降序排列，RSSI 值高的在前
        }
    }

    // MARK: - DFU 弹窗

    /// 显示DFU功能预留提示弹窗
    private func showDFUAlert() {
        // 检查是否已选择文件
        guard let firmwareURL = selectedFirmwareURL else {
            let alert = UIAlertController(
                title: "提示",
                message: "请先选择固件文件",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }

        // 检查是否已连接设备
        guard let device = selectedDevice, isConnected else {
            let alert = UIAlertController(
                title: "提示",
                message: "请先连接设备",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }

        // 获取设备信息
        let deviceUUID = device.identifier.uuidString
        let macInfo = deviceMACMap[device.identifier]
        let deviceMac = macInfo?.mac ?? ""
        let deviceMacExtra = macInfo?.macExtra
        let filePath = firmwareURL.path

        // 起始地址
        let startAddressStr = "01080000"

        addLog("🚀 开始 DFU 升级")
        addLog("设备: \(deviceNameMap[device.identifier] ?? "未知")")
        addLog("MAC: \(deviceMac)")
        addLog("文件: \(firmwareURL.lastPathComponent)")
        updateStatus("DFU 升级中...")
        
        MMTToolForNordicDFUTool.addDelegate(self)
        
        // 启动 DFU 升级
        MMTToolForNordicDFUTool.startDfu(
            deviceUUID: deviceUUID,
            deviceMac: deviceMac,
            deviceMacExtra: deviceMacExtra,
            peripheral: device,
            startAddress: startAddressStr,
            filePath: filePath
        )
        
    }

}

// MARK: - CBCentralManagerDelegate 蓝牙中心管理器代理

extension ViewController: CBCentralManagerDelegate {

    /// 蓝牙状态更新回调
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            updateStatus("蓝牙已就绪")
        case .poweredOff:
            updateStatus("蓝牙已关闭")
        case .unauthorized:
            updateStatus("蓝牙权限未授权")
        case .unsupported:
            updateStatus("此设备不支持蓝牙")
        default:
            updateStatus("蓝牙状态未知")
        }
    }

    /// 发现设备回调 - 处理扫描到的蓝牙设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // 从广播数据中提取设备名称（优先使用 kCBAdvDataLocalName）
        let localName = peripheral.name ?? ""
        let peripheralName = advertisementData["kCBAdvDataLocalName"] as? String ?? localName
        
        // 从广播数据中提取 MAC 地址
        var mac: String?
        var macExtra: String?
        if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let macList = macData.map({ String(format: "%02x", $0).uppercased() })
            mac = macList.joined(separator: ":")
            if macList.count > 6 {
                mac = macList[0..<6].joined(separator: ":")
                macExtra = macList[6..<macList.count].joined(separator: ":")
            }
            mac = mac?.uppercased()
            macExtra = macExtra?.uppercased()
        }
        
        // 根据 MAC 地址去重，保留 RSSI 最高的设备
        if let macAddress = mac {
            if let existingDeviceId = macToDeviceMap[macAddress] {
                // 已存在相同 MAC 的设备，比较 RSSI
                if let existingRSSI = deviceRSSIMap[existingDeviceId] {
                    if RSSI.intValue > existingRSSI.intValue {
                        // 新设备 RSSI 更高，替换旧设备
                        if let index = discoveredDevices.firstIndex(where: { $0.identifier == existingDeviceId }) {
                            // 清除旧设备数据
                            deviceMACMap.removeValue(forKey: existingDeviceId)
                            deviceNameMap.removeValue(forKey: existingDeviceId)
                            deviceRSSIMap.removeValue(forKey: existingDeviceId)
                            
                            // 更新为新设备
                            discoveredDevices[index] = peripheral
                            macToDeviceMap[macAddress] = peripheral.identifier
                            deviceMACMap[peripheral.identifier] = (macAddress, macExtra)
                            deviceNameMap[peripheral.identifier] = peripheralName
                            deviceRSSIMap[peripheral.identifier] = RSSI
                            
                            sortDevicesByRSSI()
                            deviceTableView.reloadData()
                            updateStatus("发现 \(discoveredDevices.count) 个设备 (更新信号更强的设备)")
                        }
                    }
                    // 否则保留现有设备，忽略新设备
                }
            } else {
                // 新设备，直接添加
                macToDeviceMap[macAddress] = peripheral.identifier
                deviceMACMap[peripheral.identifier] = (macAddress, macExtra)
                deviceNameMap[peripheral.identifier] = peripheralName
                deviceRSSIMap[peripheral.identifier] = RSSI
                discoveredDevices.append(peripheral)
                sortDevicesByRSSI()
                deviceTableView.reloadData()
                updateStatus("发现 \(discoveredDevices.count) 个设备")
            }
        } else {
            // 没有 MAC 地址的设备，按 identifier 去重
            if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                deviceNameMap[peripheral.identifier] = peripheralName
                deviceRSSIMap[peripheral.identifier] = RSSI
                discoveredDevices.append(peripheral)
                sortDevicesByRSSI()
                deviceTableView.reloadData()
                updateStatus("发现 \(discoveredDevices.count) 个设备")
            }
        }
    }

    /// 连接成功回调
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        selectedDevice = peripheral
        peripheral.delegate = self  // 设置代理以接收服务和特性回调
        let name = deviceNameMap[peripheral.identifier] ?? "未知设备"
        let mac = deviceMACMap[peripheral.identifier]?.mac ?? "未知"
        updateStatus("已连接 \(name)")
        updateConnectButton(enabled: true, isConnected: true)
        updateDFUButtonState()
        updateSelectedDeviceInfo()
        addLog("✅ 连接成功: \(name) [\(mac)]")

        // 发现所有服务
        updateStatus("正在扫描服务...")
        addLog("开始扫描服务...")
        peripheral.discoverServices(nil)
    }

    /// 断开连接回调
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let name = deviceNameMap[peripheral.identifier] ?? "未知设备"
        if let error = error {
            updateStatus("断开连接：\(error.localizedDescription)")
            addLog("❌ 断开连接: \(error.localizedDescription)")
        } else {
            updateStatus("设备已断开连接")
            addLog("断开连接: \(name)")
        }
        isConnected = false
        discoveredServices.removeAll()
        serviceCharacteristicsMap.removeAll()
        updateConnectButton(enabled: true, isConnected: false)
        updateDFUButtonState()
        updateSelectedDeviceInfo()
    }

    /// 连接失败回调
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            updateStatus("连接失败：\(error.localizedDescription)")
        } else {
            updateStatus("连接失败")
        }
        updateConnectButton(enabled: true, isConnected: false)
        updateDFUButtonState()
    }

}

// MARK: - UITableViewDataSource & UITableViewDelegate 表格数据源和代理

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    /// 返回设备列表行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }

    /// 配置并返回设备列表Cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DeviceCell.identifier, for: indexPath) as? DeviceCell else {
            return UITableViewCell()
        }

        let device = discoveredDevices[indexPath.row]
        let macInfo = deviceMACMap[device.identifier]
        let name = deviceNameMap[device.identifier] ?? "未知设备"
        let rssi = deviceRSSIMap[device.identifier]

        cell.configure(
            name: name,
            mac: macInfo?.mac,
            macExtra: macInfo?.macExtra,
            rssi: rssi
        )

        cell.selectionStyle = .default
        return cell
    }

    /// 设备列表点击事件 - 选择设备
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedDevice = discoveredDevices[indexPath.row]
        updateConnectButton(enabled: true)
        updateSelectedDeviceInfo()
        let name = selectedDevice.map { deviceNameMap[$0.identifier] ?? "未知设备" } ?? "未知设备"
        updateStatus("已选择：\(name)")
    }

    /// 返回Cell高度（自动计算）
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    /// 返回Cell预估高度
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - MMTToolForNordicDFUDelegate DFU代理

extension ViewController: MMTToolForNordicDFUDelegate {

    /// DFU模式进入成功回调
    func mmtToolForNordicUnitDidEnter(_ unit: MMTToolForNordicDFUToolUnit?) {
        print("✅ DFU Unit 进入成功")
        updateStatus("DFU 模式准备就绪")
    }

    /// DFU模式进入失败回调
    func mmtToolForNordicUnitDidFailToEnter(_ unit: MMTToolForNordicDFUToolUnit?, error: Error?) {
        print("❌ DFU Unit 进入失败: \(error?.localizedDescription ?? "未知错误")")
        updateStatus("DFU 模式进入失败")
        MMTToolForNordicDFUTool.removeDelegate(self)
    }

    /// DFU升级开始回调
    func mmtToolForNordicUnitDFUDidBegin(_ unit: MMTToolForNordicDFUToolUnit?) {
        print("🚀 DFU 开始")
        updateStatus("DFU 升级进行中...")
    }

    /// DFU升级进度变化回调
    func mmtToolForNordicUnitDFUDidChangeProgress(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int) {
        print("📊 DFU 进度: \(progress)%")
        updateStatus("DFU 进度: \(progress)%")
    }
    
    /// DFU升级完成回调
    func mmtToolForNordicUnitDFUDidEnd(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int?, error: Error?) {
        if let error = error {
            print("❌ DFU 失败: \(error.localizedDescription)")
            updateStatus("DFU 失败: \(error.localizedDescription)")
        } else {
            print("✅ DFU 完成，进度: \(progress ?? 100)%")
            updateStatus("DFU 升级完成！进度: \(progress ?? 100)%")
            MMTToolForNordicDFUTool.removeDelegate(self)
        }
        updateDFUButton(enabled: true)
        MMTToolForNordicDFUTool.removeDelegate(self)
    }

    /// DFU错误信息回调
    func mmtToolForNordicUnitDidShowErrorMessage(_ unit: MMTToolForNordicDFUToolUnit?, stage: String?, error: Error?) {
        print("⚠️ DFU 阶段[\(stage ?? "")] 错误: \(error?.localizedDescription ?? "")")
        updateStatus("错误[\(stage ?? "")]: \(error?.localizedDescription ?? "未知错误")")
        MMTToolForNordicDFUTool.removeDelegate(self)
    }

    /// 获取自定义UUID - 返回 DFU 服务和特性
    func mmtToolForNordicUnitGetUUID(_ unit: MMTToolForNordicDFUToolUnit?) -> MMTToolForNordicDFUDelegate.DFUServerTurple? {
        guard let device = selectedDevice else {
            addLog("❌ 获取 UUID 失败: 未选择设备")
            return nil
        }

        // 遍历所有服务，查找 DFU 服务
        for service in discoveredServices {
            let serviceUUID = service.uuid.uuidString.uppercased()
            addLog("检查服务: \(serviceUUID)")

            // Nordic DFU Service 通常包含 FE59 或其他自定义 UUID
            // 您需要根据实际设备的 DFU Service UUID 进行匹配
            // 常见的 DFU Service UUID: 0000FE59-0000-1000-8000-00805F9B34FB

            // 获取该服务的特性
            guard let characteristics = serviceCharacteristicsMap[service.uuid],
                  !characteristics.isEmpty else {
                continue
            }

            addLog("  找到 \(characteristics.count) 个特性")

            // 根据特性属性或 UUID 找到对应的特性
            var readCharacter: CBCharacteristic?
            var writeCharacter: CBCharacteristic?
            var controlCharacter: CBCharacteristic?

            for char in characteristics {
                let charUUID = char.uuid.uuidString.uppercased()
                let props = char.properties

                addLog("    特性: \(charUUID)")
                addLog("      属性: \(characteristicPropertiesDescription(props))")

                // 方式1: 根据 UUID 匹配（推荐）
                // Nordic DFU 常见特性 UUID:
                // Control Point: 8EC90001-F315-4F60-9FB8-838830DAEA50
                // Packet: 8EC90002-F315-4F60-9FB8-838830DAEA50
                // Version: 8EC90003-F315-4F60-9FB8-838830DAEA50

                if charUUID.contains("8EC9") || charUUID.contains("0001") {
                    controlCharacter = char
                    addLog("      → 控制特性")
                } else if charUUID.contains("8EC9") || charUUID.contains("0002") {
                    writeCharacter = char
                    addLog("      → 写特性")
                } else if charUUID.contains("8EC9") || charUUID.contains("0003") {
                    readCharacter = char
                    addLog("      → 读特性")
                }

                // 方式2: 根据属性匹配（备用）
                if controlCharacter == nil && props.contains(.write) && props.contains(.notify) {
                    controlCharacter = char
                }
                if writeCharacter == nil && props.contains(.writeWithoutResponse) {
                    writeCharacter = char
                }
                if readCharacter == nil && props.contains(.read) {
                    readCharacter = char
                }
            }

            // 如果找到了必要的特性，返回元组
            if readCharacter != nil || writeCharacter != nil || controlCharacter != nil {
                addLog("✅ 找到 DFU 服务: \(serviceUUID)")
                return (service, readCharacter, writeCharacter, controlCharacter)
            }
        }

        addLog("❌ 未找到 DFU 服务和特性")
        return nil
    }

    /// 获取当前选中的设备
    func mmtToolForNordicUnitGetPeripheral(_ unit: MMTToolForNordicDFUToolUnit?) -> CBPeripheral? {
        return selectedDevice
    }
}

// MARK: - DeviceCell 设备列表Cell

class DeviceCell: UITableViewCell {

    /// Cell重用标识符
    static let identifier = "DeviceCell"

    /// 设备名称标签
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// MAC地址标签
    private let macLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// RSSI信号强度标签
    private let rssiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// MAC额外数据标签
    private let macExtraLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    /// 初始化方法
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    /// 必需的初始化方法（不支持从Storyboard初始化）
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 设置Cell UI布局
    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(macLabel)
        contentView.addSubview(rssiLabel)
        contentView.addSubview(macExtraLabel)
        
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: rssiLabel.leadingAnchor, constant: -8),
            
            rssiLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            rssiLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rssiLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            macLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            macLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            
            macExtraLabel.topAnchor.constraint(equalTo: macLabel.bottomAnchor, constant: 2),
            macExtraLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            macExtraLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    /// 配置Cell显示内容
    func configure(name: String, mac: String?, macExtra: String?, rssi: NSNumber?) {
        nameLabel.text = name

        if let mac = mac {
            macLabel.text = "MAC: \(mac)"
        } else {
            macLabel.text = "MAC: 未知"
        }

        if let extra = macExtra {
            macExtraLabel.text = "Extra: \(extra)"
            macExtraLabel.isHidden = false
        } else {
            macExtraLabel.isHidden = true
        }

        if let rssi = rssi {
            rssiLabel.text = "\(rssi) dBm"
            // 根据 RSSI 值设置颜色：>=-60绿色，-60~-80橙色，<-80红色
            let rssiValue = rssi.intValue
            if rssiValue >= -60 {
                rssiLabel.textColor = .systemGreen
            } else if rssiValue >= -80 {
                rssiLabel.textColor = .systemOrange
            } else {
                rssiLabel.textColor = .systemRed
            }
        } else {
            rssiLabel.text = "N/A"
            rssiLabel.textColor = .secondaryLabel
        }

        // 适配暗黑模式
        nameLabel.textColor = .label
        macLabel.textColor = .secondaryLabel
        macExtraLabel.textColor = .tertiaryLabel
        backgroundColor = .systemBackground
    }

    /// 界面特征变化回调 - 用于暗黑模式切换
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // 暗黑模式切换时自动更新颜色
        nameLabel.textColor = .label
        macLabel.textColor = .secondaryLabel
        macExtraLabel.textColor = .tertiaryLabel
        backgroundColor = .systemBackground
    }
}

// MARK: - CBPeripheralDelegate

extension ViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            updateStatus("扫描服务失败：\(error.localizedDescription)")
            addLog("❌ 扫描服务失败: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else {
            updateStatus("未发现服务")
            addLog("⚠️ 未发现服务")
            return
        }

        discoveredServices = services
        updateStatus("发现 \(services.count) 个服务，正在扫描特性...")
        addLog("发现 \(services.count) 个服务")

        // 扫描每个服务的特性
        for service in services {
            addLog("📂 Service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    /// 发现特性回调
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            updateStatus("扫描特性失败：\(error.localizedDescription)")
            addLog("❌ 扫描特性失败: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else {
            return
        }

        // 存储特性
        serviceCharacteristicsMap[service.uuid] = characteristics

        // 打印服务信息
        addLog("  扫描到 \(characteristics.count) 个特性:")
        for characteristic in characteristics {
            let props = characteristicPropertiesDescription(characteristic.properties)
            addLog("    └─ \(characteristic.uuid) [\(props)]")

            peripheral.setNotifyValue(true, for: characteristic)
        }

        // 检查是否所有服务的特性都已扫描完成
        let totalCharacteristics = serviceCharacteristicsMap.values.flatMap { $0 }.count
        let scannedServices = serviceCharacteristicsMap.count
        let totalServices = discoveredServices.count

        updateStatus("已扫描 \(scannedServices)/\(totalServices) 个服务，\(totalCharacteristics) 个特性")
        
        // 所有服务扫描完成
        if scannedServices == totalServices {
            updateStatus("扫描完成：\(totalServices) 个服务，\(totalCharacteristics) 个特性")
            addLog("✅ 服务扫描完成: \(totalServices) 个服务, \(totalCharacteristics) 个特性")
        }
    }

    /// 将特性属性转换为可读的描述字符串
    private func characteristicPropertiesDescription(_ properties: CBCharacteristicProperties) -> String {
        var descriptions: [String] = []
        
        if properties.contains(.read) { descriptions.append("Read") }
        if properties.contains(.write) { descriptions.append("Write") }
        if properties.contains(.writeWithoutResponse) { descriptions.append("WriteWithoutResponse") }
        if properties.contains(.notify) { descriptions.append("Notify") }
        if properties.contains(.indicate) { descriptions.append("Indicate") }
        if properties.contains(.broadcast) { descriptions.append("Broadcast") }
        if properties.contains(.authenticatedSignedWrites) { descriptions.append("SignedWrite") }
        if properties.contains(.extendedProperties) { descriptions.append("Extended") }
        if properties.contains(.notifyEncryptionRequired) { descriptions.append("NotifyEncrypt") }
        if properties.contains(.indicateEncryptionRequired) { descriptions.append("IndicateEncrypt") }
        
        return descriptions.isEmpty ? "None" : descriptions.joined(separator: ", ")
    }
}

// MARK: - UIDocumentPickerDelegate 文件选择代理

extension ViewController: UIDocumentPickerDelegate {

    /// 文件选择完成回调
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        selectedFirmwareURL = url

        // 获取文件信息
        let fileName = url.lastPathComponent
        let filePath = url.path

        addLog("已选择文件: \(fileName)")
        addLog("文件路径: \(filePath)")

        // 更新状态
        updateStatus("已选择固件文件: \(fileName)")

        // 如果已连接设备，启用 DFU 按钮
        updateDFUButtonState()
    }

    /// 文件选择取消回调
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        addLog("取消选择文件")
    }
}
