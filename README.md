# MMTToolForNordicTool

[![CI Status](https://img.shields.io/travis/NealWills/MMTToolForNordicTool.svg?style=flat)](https://travis-ci.org/NealWills/MMTToolForNordicTool)
[![Version](https://img.shields.io/cocoapods/v/MMTToolForNordicTool.svg?style=flat)](https://cocoapods.org/pods/MMTToolForNordicTool)
[![License](https://img.shields.io/cocoapods/l/MMTToolForNordicTool.svg?style=flat)](https://cocoapods.org/pods/MMTToolForNordicTool)
[![Platform](https://img.shields.io/cocoapods/p/MMTToolForNordicTool.svg?style=flat)](https://cocoapods.org/pods/MMTToolForNordicTool)

## Introduction

MMTToolForNordicTool is a Bluetooth tool library for Nordic chip devices, providing device scanning, connection, DFU upgrade and other functions. The example project demonstrates a complete Bluetooth device management workflow.

## Features

### Core Features

- ✅ **Bluetooth Device Scanning**
  - Scan nearby BLE devices
  - Extract device name and MAC address from advertisement data
  - Real-time RSSI signal strength display
  - Automatic sorting by signal strength

- ✅ **Intelligent Device Management**
  - MAC address deduplication (keeps the device with strongest signal)
  - Device information card display
  - Real-time connection status updates

- ✅ **Device Connection**
  - One-click connect/disconnect
  - Automatic service and characteristic scanning
  - Characteristic property parsing (Read/Write/Notify, etc.)

- ✅ **Command Log**
  - Real-time operation log recording
  - Timestamp markers
  - Support for clearing logs

- ✅ **DFU Upgrade (Reserved)**
  - Nordic DFU upgrade support
  - Progress callbacks
  - Error handling

### UI Features

- 🎨 **Perfect Dark Mode Support**
  - Automatic adaptation to system appearance mode
  - Semantic color usage

- 📱 **Modern Interface**
  - Card-style design
  - Rounded buttons and containers
  - Responsive layout

## Example Project

### Running the Example

To run the example project, follow these steps:

1. Clone the repository
```bash
git clone https://github.com/NealWills/MMTToolForNordicTool.git
```

2. Navigate to the Example directory
```bash
cd MMTToolForNordicTool/Example
```

3. Install dependencies
```bash
pod install
```

4. Open `MMTToolForNordicTool.xcworkspace` and run the project

### Usage Guide

#### 1. Scan Devices

Click the "Start Scan" button to automatically scan nearby Bluetooth devices. The device list will be sorted by RSSI signal strength from high to low.

#### 2. Select Device

Click to select a device from the list. The device information card will display detailed information about the selected device:
- Device Name
- MAC Address
- Extra Data (if available)
- Connection Status

#### 3. Connect Device

Click the "Connect Device" button to connect to the selected device. After successful connection:
- Button changes to "Disconnect" (red)
- Automatically scans device services and characteristics
- Log area shows scanning progress

#### 4. View Logs

All operations are recorded in the command log area, including:
- Scan start/stop
- Device connect/disconnect
- Service scanning progress
- Characteristic discovery records

## Code Examples

### ViewController Usage Example

The following examples demonstrate how to use the MMTToolForNordicTool library to implement complete Bluetooth device scanning, connection, and DFU upgrade functionality:

#### 1. Configure DFU Tool

```swift
import MMTToolForNordicTool

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure DFU manager
        MMTToolForNordicDFUTool.configManager()
        
        // Add DFU delegate
        MMTToolForNordicDFUTool.addDelegate(self)
        
        // Configure log system
        MMTToolForNordicLog.configure { config in
            config.minimumLevel = .debug
            config.enableConsole = true
            config.cacheEnabled = true
            config.cacheLimit = 500
            config.enableColors = true
        }
        
        // Set custom log handler
        MMTToolForNordicLog.setCustomHandler { [weak self] entry in
            DispatchQueue.main.async {
                self?.addLogToUI(entry.simplifiedMessage)
            }
        }
    }
    
    deinit {
        // Remove delegate
        MMTToolForNordicDFUTool.removeDelegate(self)
    }
}
```

#### 2. Bluetooth Device Scanning

```swift
extension ViewController: CBCentralManagerDelegate {
    
    /// Start scanning for Bluetooth devices
    private func startScanning() {
        guard centralManager.state == .poweredOn else {
            updateStatus("Bluetooth is not powered on")
            return
        }
        
        // Clear old data
        discoveredDevices.removeAll()
        deviceMACMap.removeAll()
        deviceNameMap.removeAll()
        deviceRSSIMap.removeAll()
        macToDeviceMap.removeAll()
        
        // Start scanning
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
    }
    
    /// Device discovery callback
    func centralManager(_ central: CBCentralManager, 
                       didDiscover peripheral: CBPeripheral,
                       advertisementData: [String: Any], 
                       rssi RSSI: NSNumber) {
        
        // Extract device name
        let localName = peripheral.name ?? ""
        let peripheralName = advertisementData["kCBAdvDataLocalName"] as? String ?? localName
        
        // Extract MAC address
        var mac: String?
        var macExtra: String?
        if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let macList = macData.map({ String(format: "%02x", $0).uppercased() })
            mac = macList[0..<6].joined(separator: ":")
            if macList.count > 6 {
                macExtra = macList[6..<macList.count].joined(separator: ":")
            }
        }
        
        // Deduplicate by MAC address, keep device with highest RSSI
        if let macAddress = mac {
            if let existingDeviceId = macToDeviceMap[macAddress] {
                if let existingRSSI = deviceRSSIMap[existingDeviceId] {
                    if RSSI.intValue > existingRSSI.intValue {
                        // Replace with device having stronger signal
                        updateDevice(peripheral, macAddress, macExtra, peripheralName, RSSI)
                    }
                }
            } else {
                // Add new device
                addDevice(peripheral, macAddress, macExtra, peripheralName, RSSI)
            }
        }
    }
}
```

#### 3. Device Connection and Service Scanning

```swift
extension ViewController {
    
    /// Device connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.delegate = self
        
        // Automatically scan services and characteristics
        peripheral.discoverServices(nil)
    }
}

extension ViewController: CBPeripheralDelegate {
    
    /// Services discovered callback
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        discoveredServices = services
        
        // Scan characteristics for each service
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    /// Characteristics discovered callback
    func peripheral(_ peripheral: CBPeripheral, 
                   didDiscoverCharacteristicsFor service: CBService, 
                   error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        // Store characteristics
        serviceCharacteristicsMap[service.uuid] = characteristics
        
        // Subscribe to notifications
        for characteristic in characteristics {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
}
```

#### 4. DFU Upgrade Implementation

```swift
extension ViewController {
    
    /// Start DFU upgrade
    private func startDFUUpgrade() {
        guard let device = selectedDevice,
              let firmwareURL = selectedFirmwareURL,
              isConnected else {
            return
        }
        
        let deviceUUID = device.identifier.uuidString
        let macInfo = deviceMACMap[device.identifier]
        let deviceMac = macInfo?.mac ?? ""
        let deviceMacExtra = macInfo?.macExtra ?? ""
        let filePath = firmwareURL.path
        let startAddress = "01080000"  // Start address
        
        // Start DFU upgrade
        MMTToolForNordicDFUTool.startDfu(
            deviceUUID: deviceUUID,
            deviceMac: deviceMac,
            deviceMacExtra: deviceMacExtra,
            peripheral: device,
            startAddress: startAddress,
            filePath: filePath
        )
    }
}

// MARK: - DFU Delegate Implementation
extension ViewController: MMTToolForNordicDFUDelegate {
    
    /// DFU mode entered successfully
    func mmtToolForNordicUnitDidEnter(_ unit: MMTToolForNordicDFUToolUnit?) {
        print("✅ DFU Unit entered successfully")
        updateStatus("DFU mode ready")
    }
    
    /// DFU mode entry failed
    func mmtToolForNordicUnitDidFailToEnter(_ unit: MMTToolForNordicDFUToolUnit?, error: Error?) {
        print("❌ DFU Unit entry failed: \(error?.localizedDescription ?? "")")
        updateStatus("DFU mode entry failed")
    }
    
    /// DFU upgrade started
    func mmtToolForNordicUnitDFUDidBegin(_ unit: MMTToolForNordicDFUToolUnit?) {
        print("🚀 DFU started")
        updateStatus("DFU upgrade in progress...")
    }
    
    /// DFU progress changed
    func mmtToolForNordicUnitDFUDidChangeProgress(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int) {
        print("📊 DFU progress: \(progress)%")
        updateStatus("DFU progress: \(progress)%")
    }
    
    /// DFU completed
    func mmtToolForNordicUnitDFUDidEnd(_ unit: MMTToolForNordicDFUToolUnit?, progress: Int?, error: Error?) {
        if let error = error {
            print("❌ DFU failed: \(error.localizedDescription)")
            updateStatus("DFU failed: \(error.localizedDescription)")
        } else {
            print("✅ DFU completed, progress: \(progress ?? 100)%")
            updateStatus("DFU upgrade completed!")
        }
    }
    
    /// Get DFU service and characteristics
    func mmtToolForNordicUnitGetUUID(_ unit: MMTToolForNordicDFUToolUnit?) -> MMTToolForNordicDFUDelegate.DFUServerTurple? {
        guard let device = selectedDevice else { return nil }
        
        // Iterate through discovered services
        for service in discoveredServices {
            guard let characteristics = serviceCharacteristicsMap[service.uuid] else {
                continue
            }
            
            // Find DFU related characteristics
            var readCharacter: CBCharacteristic?
            var writeCharacter: CBCharacteristic?
            var controlCharacter: CBCharacteristic?
            
            for char in characteristics {
                let charUUID = char.uuid.uuidString.uppercased()
                
                // Match DFU characteristics by UUID
                if charUUID.contains("8EC9") || charUUID.contains("0001") {
                    controlCharacter = char
                } else if charUUID.contains("0002") {
                    writeCharacter = char
                } else if charUUID.contains("0003") {
                    readCharacter = char
                }
            }
            
            if readCharacter != nil || writeCharacter != nil || controlCharacter != nil {
                return (service, readCharacter, writeCharacter, controlCharacter)
            }
        }
        
        return nil
    }
    
    /// Get currently selected device
    func mmtToolForNordicUnitGetPeripheral(_ unit: MMTToolForNordicDFUToolUnit?) -> CBPeripheral? {
        return selectedDevice
    }
}
```

## Technical Implementation

### Device Information Extraction

```swift
// Extract device name from advertisement data (prefer kCBAdvDataLocalName)
let peripheralName = advertisementData["kCBAdvDataLocalName"] as? String ?? peripheral.name ?? ""

// Extract MAC address from manufacturer data
if let macData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
    let macList = macData.map({ String(format: "%02x", $0).uppercased() })
    let mac = macList[0..<6].joined(separator: ":")
}
```

### RSSI Signal Strength Indication

| RSSI Range | Color | Signal Strength |
|-----------|------|---------|
| ≥ -60 dBm | 🟢 Green | Strong |
| -60 ~ -80 dBm | 🟠 Orange | Medium |
| < -80 dBm | 🔴 Red | Weak |

### Service Characteristic Scanning

After successful connection, automatically scans all services and characteristics, and parses characteristic properties:
- Read - Readable
- Write - Writable
- WriteWithoutResponse - Write without response
- Notify - Notification
- Indicate - Indication
- Broadcast - Broadcast

## System Requirements

- iOS 12.0+
- Xcode 12.0+
- Swift 5.0+

## Installation

MMTToolForNordicTool is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'MMTToolForNordicTool'
```

## Permission Configuration

Add the following permissions to your `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need Bluetooth permission to scan and connect devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Need Bluetooth permission to communicate with devices</string>
```

## Project Structure

```
MMTToolForNordicTool/
├── Example/
│   └── MMTToolForNordicTool/
│       ├── ViewController.swift       # Example main view controller
│       └── AppDelegate.swift          # Application delegate
├── MMTToolForNordicTool/
│   ├── Classes/                       # Core functionality classes
│   └── MMTToolForNordicTool.h         # Main header file
├── LICENSE
└── README.md
```

## Changelog

### Version 1.0.0
- Implemented Bluetooth device scanning functionality
- Implemented device connection and disconnection
- Implemented MAC address extraction and deduplication
- Implemented RSSI signal strength sorting
- Implemented service and characteristic scanning
- Implemented command log recording
- Added dark mode support
- Reserved DFU upgrade interface

## Author

NealWills, Donghn@maxeye.com

## License

MMTToolForNordicTool is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
