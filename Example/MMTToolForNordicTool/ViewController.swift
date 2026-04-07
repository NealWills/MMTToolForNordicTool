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
    
    private lazy var scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始扫描", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deviceTableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
        tableView.isHidden = true
        return tableView
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "准备就绪"
        label.textAlignment = .center
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private lazy var connectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("连接设备", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    private lazy var dfuButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.setTitle("开始 DFU (预留)", for: .normal)
        button.backgroundColor = .systemOrange
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.addTarget(self, action: #selector(dfuButtonTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    // MARK: - Properties
    
    private var centralManager: CBCentralManager!
    private var discoveredDevices: [CBPeripheral] = []
    private var selectedDevice: CBPeripheral?
    private var isConnected: Bool = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBluetooth()
        
        // 配置 DFU 工具
        MMTToolForNordicDFUTool.configManager()
        MMTToolForNordicDFUTool.addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
        MMTToolForNordicDFUTool.removeDelegate(self)
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        let stackView = UIStackView(arrangedSubviews: [
            scanButton,
            statusLabel,
            deviceTableView,
            connectButton,
            dfuButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scanButton.heightAnchor.constraint(equalToConstant: 44),
            connectButton.heightAnchor.constraint(equalToConstant: 44),
            dfuButton.heightAnchor.constraint(equalToConstant: 50),
            deviceTableView.heightAnchor.constraint(equalToConstant: 250),
            
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Bluetooth Setup
    
    private func setupBluetooth() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Actions
    
    @objc private func scanButtonTapped(_ sender: UIButton) {
        if sender.currentTitle == "开始扫描" {
            startScanning()
        } else {
            stopScanning()
        }
    }
    
    @objc private func connectButtonTapped(_ sender: UIButton) {
        guard let device = selectedDevice else { return }
        centralManager.connect(device, options: nil)
        updateStatus("正在连接 \(device.name ?? "未知设备")...")
    }
    
    @objc private func dfuButtonTapped(_ sender: UIButton) {
        // TODO: 实现 DFU 功能
        showDFUAlert()
    }
    
    // MARK: - Bluetooth Operations
    
    private func startScanning() {
        guard centralManager.state == .poweredOn else {
            updateStatus("蓝牙未开启")
            return
        }
        
        discoveredDevices.removeAll()
        deviceTableView.reloadData()
        deviceTableView.isHidden = false
        
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        
        scanButton.setTitle("停止扫描", for: .normal)
        scanButton.backgroundColor = .systemRed
        updateStatus("正在扫描设备...")
    }
    
    private func stopScanning() {
        centralManager.stopScan()
        scanButton.setTitle("开始扫描", for: .normal)
        scanButton.backgroundColor = .systemBlue
        updateStatus("已停止扫描")
    }
    
    // MARK: - UI Updates
    
    private func updateStatus(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
        }
    }
    
    private func updateConnectButton(enabled: Bool) {
        connectButton.isEnabled = enabled
        connectButton.alpha = enabled ? 1.0 : 0.5
    }
    
    private func updateDFUButton(enabled: Bool) {
        dfuButton.isEnabled = enabled
        dfuButton.alpha = enabled ? 1.0 : 0.5
    }
    
    // MARK: - DFU Alert
    
    private func showDFUAlert() {
        let alert = UIAlertController(title: "DFU 功能", message: "此功能预留中\n\n当前选中设备：\n\(selectedDevice?.name ?? "未知")\n\nMAC地址：\(selectedDevice?.identifier.uuidString ?? "")", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

}

// MARK: - CBCentralManagerDelegate

extension ViewController: CBCentralManagerDelegate {
    
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // 避免重复添加
        if !discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredDevices.append(peripheral)
            deviceTableView.reloadData()
            updateStatus("发现 \(discoveredDevices.count) 个设备")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        selectedDevice = peripheral
        updateStatus("已连接 \(peripheral.name ?? "未知设备")")
        updateConnectButton(enabled: false)
        updateDFUButton(enabled: true)
        
        // 延迟发现服务
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            updateStatus("断开连接：\(error.localizedDescription)")
        } else {
            updateStatus("设备已断开连接")
        }
        isConnected = false
        updateConnectButton(enabled: true)
        updateDFUButton(enabled: false)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            updateStatus("连接失败：\(error.localizedDescription)")
        } else {
            updateStatus("连接失败")
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let device = discoveredDevices[indexPath.row]
        cell.textLabel?.text = device.name ?? "未知设备 (\(device.identifier.uuidString.prefix(8)))"
        cell.detailTextLabel?.text = "RSSI: \(device.name ?? "N/A")"
        cell.selectionStyle = .default
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedDevice = discoveredDevices[indexPath.row]
        updateConnectButton(enabled: true)
        updateStatus("已选择：\(selectedDevice?.name ?? "未知设备")")
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}

// MARK: - MMTToolForNordicDFUDelegate

extension ViewController: MMTToolForNordicDFUDelegate {
    
    func mmtToolForNordicUnitDidEnter(_ unit: MMTToolForNordicDFUToolUnit?) {
        print("✅ DFU Unit 进入成功")
        updateStatus("DFU 模式准备就绪")
    }
    
    func mmtToolForNordicUnitDidFailToEnter(_ unit: MMTToolForNordicDFUToolUnit?, error: Error?) {
        print("❌ DFU Unit 进入失败: \(error?.localizedDescription ?? "未知错误")")
        updateStatus("DFU 模式进入失败")
    }
    
    func mmtToolForNordicUnitDFUDidBegin(_ unit: MMTToolForNordicDFUToolUnit?) {
        print("🚀 DFU 开始")
        updateStatus("DFU 升级进行中...")
    }
    
    func mmtToolForNordicUnitDFUDidChangeProgress(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int) {
        print("📊 DFU 进度: \(progress)%")
        updateStatus("DFU 进度: \(progress)%")
    }
    
    func mmtToolForNordicUnitDFUDidEnd(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int?, error: Error?) {
        if let error = error {
            print("❌ DFU 失败: \(error.localizedDescription)")
            updateStatus("DFU 失败: \(error.localizedDescription)")
        } else {
            print("✅ DFU 完成，进度: \(progress ?? 100)%")
            updateStatus("DFU 升级完成！进度: \(progress ?? 100)%")
        }
        updateDFUButton(enabled: true)
    }
    
    func mmtToolForNordicUnitDidShowErrorMessage(_ unit: MMTToolForNordicDFUToolUnit?, stage: String?, error: Error?) {
        print("⚠️ DFU 阶段[\(stage ?? "")] 错误: \(error?.localizedDescription ?? "")")
        updateStatus("错误[\(stage ?? "")]: \(error?.localizedDescription ?? "未知错误")")
    }
    
    func mmtToolForNordicUnitGetUUID(_ unit: MMTToolForNordicDFUToolUnit?) -> MMTToolForNordicDFUDelegate.DFUServerTurple? {
        // TODO: 返回自定义的 Service 和 Characteristic UUID
        return nil
    }
    
    func mmtToolForNordicUnitGetPeripheral(_ unit: MMTToolForNordicDFUToolUnit?) -> CBPeripheral? {
        return selectedDevice
    }
}
